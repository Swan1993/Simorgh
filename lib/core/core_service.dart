import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'core_config.dart';
import 'core_process.dart';
import 'failures/failure_code.dart';
import 'logging/log_entry.dart';
import 'logging/log_service.dart';
import 'proxy_manager.dart';

enum CoreState { stopped, starting, running, stopping, failed }

class CoreStartResult {
  const CoreStartResult.success(this.configPath) : failure = null;
  const CoreStartResult.failure(this.failure) : configPath = null;

  final String? configPath;
  final FailureCode? failure;
  bool get isSuccess => failure == null;
}

class CoreService {
  CoreService({
    required LogService logger,
    CoreLauncher? launcher,
    SystemProxyManager? proxyManager,
    CoreConfigBuilder? configBuilder,
  }) : _logger = logger,
       _launcher = launcher ?? ProcessCoreLauncher(),
       _proxyManager = proxyManager ?? WindowsSystemProxyManager(),
       _configBuilder = configBuilder ?? CoreConfigBuilder();

  final LogService _logger;
  final CoreLauncher _launcher;
  final SystemProxyManager _proxyManager;
  final CoreConfigBuilder _configBuilder;
  CoreHandle? _handle;
  File? _configFile;
  bool _proxyEnabled = false;
  Future<CoreStartResult>? _startOperation;
  int _generation = 0;
  bool _stopRequested = false;
  CoreState state = CoreState.stopped;
  FailureCode? lastFailure;

  Future<CoreStartResult> start(CoreLaunchConfig launch) {
    if (state == CoreState.running) {
      return Future<CoreStartResult>.value(
        CoreStartResult.success(_configFile?.path ?? ''),
      );
    }
    final generation = ++_generation;
    _stopRequested = false;
    state = CoreState.starting;
    lastFailure = null;
    final operation = _startInternal(launch, generation);
    _startOperation = operation;
    return operation.whenComplete(() {
      if (identical(_startOperation, operation)) {
        _startOperation = null;
      }
    });
  }

  Future<CoreStartResult> _startInternal(
    CoreLaunchConfig launch,
    int generation,
  ) async {
    final binary = File(launch.binaryPath);
    if (!binary.existsSync()) {
      return _failure(FailureCode.coreMissing, 'Core executable was not found.');
    }

    try {
      _ensureStartCurrent(generation);
      await _verifyHash(binary, launch.expectedSha256);
      _ensureStartCurrent(generation);
      final configFile = await _writeTemporaryConfig(launch);
      _ensureStartCurrent(generation);
      _configFile = configFile;
      if (launch.useSystemProxy) {
        await _proxyManager.enable(host: '127.0.0.1', port: launch.localHttpPort);
        _proxyEnabled = true;
      }
      _ensureStartCurrent(generation);
      final handle = await _launcher.launch(binary.path, ['run', '-c', configFile.path]);
      _ensureStartCurrent(generation);
      _handle = handle;
      _listenToOutput(handle.stdout, LogLevel.info, 'core.stdout');
      _listenToOutput(handle.stderr, LogLevel.warning, 'core.stderr');
      unawaited(_watchExit(handle));
      if (launch.verifyLocalPort) {
        await _waitForLocalPort(launch.localHttpPort);
      }
      state = CoreState.running;
      _logger.info('core', 'Core process started', metadata: {'config': '<TEMPORARY>'});
      return CoreStartResult.success(configFile.path);
    } on CoreServiceException catch (error) {
      return _failure(error.code, error.message);
    } on ArgumentError catch (error) {
      return _failure(FailureCode.coreConfigInvalid, 'Core configuration is invalid: $error');
    } on Object catch (error) {
      await _cleanupAfterFailure();
      return _failure(FailureCode.coreCrash, 'Core process could not start: $error');
    }
  }

  Future<void> stop() async {
    if (state == CoreState.stopped && _startOperation == null) {
      return;
    }
    _generation++;
    _stopRequested = true;
    state = CoreState.stopping;
    final handle = _handle;
    final starting = _startOperation;
    try {
      handle?.kill();
      if (handle != null) {
        await handle.exitCode.timeout(const Duration(seconds: 3), onTimeout: () => -1);
      }
      if (starting != null) {
        try {
          await starting.timeout(const Duration(seconds: 3));
        } on TimeoutException {
          // Cleanup below still removes the temporary config and restores the
          // proxy even if a launcher is stuck.
        }
      }
    } finally {
      await _cleanupAfterFailure();
      state = CoreState.stopped;
      _stopRequested = false;
      _logger.info('core', 'Core process stopped');
    }
  }

  Future<CoreStartResult> _failure(FailureCode code, String message) async {
    lastFailure = code;
    if (_stopRequested) {
      state = CoreState.stopped;
      _logger.info('core', 'Core start cancelled.');
    } else {
      state = CoreState.failed;
      _logger.error('core', message, errorCode: code.wireCode);
    }
    await _cleanupAfterFailure();
    return CoreStartResult.failure(code);
  }

  void _ensureStartCurrent(int generation) {
    if (generation != _generation || _stopRequested) {
      throw const CoreServiceException(
        FailureCode.verifyTimeout,
        'Core start was cancelled.',
      );
    }
  }

  Future<void> _waitForLocalPort(int port) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      try {
        final socket = await Socket.connect('127.0.0.1', port, timeout: const Duration(milliseconds: 250));
        socket.destroy();
        return;
      } on Object {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
    throw const CoreServiceException(FailureCode.verifyTimeout, 'Core local proxy did not become ready.');
  }

  Future<void> _verifyHash(File binary, String? expected) async {
    if (expected == null || expected.trim().isEmpty) {
      _logger.warning('core', 'Core hash was not supplied; verification skipped.');
      return;
    }
    final actual = sha256.convert(await binary.readAsBytes()).toString();
    if (actual.toLowerCase() != expected.trim().toLowerCase()) {
      throw const CoreServiceException(FailureCode.coreConfigInvalid, 'Core SHA-256 verification failed.');
    }
  }

  Future<File> _writeTemporaryConfig(CoreLaunchConfig launch) async {
    final path = '${Directory.systemTemp.path}${Platform.pathSeparator}simorgh-core-${DateTime.now().microsecondsSinceEpoch}.json';
    final file = File(path);
    await file.writeAsString(jsonEncode(_configBuilder.build(launch)), flush: true);
    return file;
  }

  void _listenToOutput(Stream<List<int>> output, LogLevel level, String component) {
    output.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      if (level == LogLevel.warning) {
        _logger.warning(component, line);
      } else {
        _logger.info(component, line);
      }
    });
  }

  Future<void> _watchExit(CoreHandle handle) async {
    final code = await handle.exitCode;
    if (identical(handle, _handle) && state == CoreState.running) {
      state = CoreState.failed;
      lastFailure = FailureCode.coreCrash;
      _logger.error('core', 'Core process exited unexpectedly with code $code', errorCode: FailureCode.coreCrash.wireCode);
      await _cleanupAfterFailure();
    }
  }

  Future<void> _cleanupAfterFailure() async {
    if (_proxyEnabled) {
      try {
        await _proxyManager.restore();
      } finally {
        _proxyEnabled = false;
      }
    }
    final config = _configFile;
    _configFile = null;
    _handle = null;
    if (config != null && config.existsSync()) {
      await config.delete();
    }
  }
}

class CoreServiceException implements Exception {
  const CoreServiceException(this.code, this.message);
  final FailureCode code;
  final String message;
}
