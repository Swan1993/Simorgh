import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:simorgh/core/core_config.dart';
import 'package:simorgh/core/core_process.dart';
import 'package:simorgh/core/core_service.dart';
import 'package:simorgh/core/failures/failure_code.dart';
import 'package:simorgh/core/logging/log_service.dart';
import 'package:simorgh/core/proxy_manager.dart';

class _FakeHandle implements CoreHandle {
  final _exit = Completer<int>();
  final _stdout = StreamController<List<int>>();
  final _stderr = StreamController<List<int>>();

  @override
  Stream<List<int>> get stdout => _stdout.stream;
  @override
  Stream<List<int>> get stderr => _stderr.stream;
  @override
  Future<int> get exitCode => _exit.future;
  @override
  bool kill() {
    if (!_exit.isCompleted) _exit.complete(0);
    return true;
  }
}

class _FakeLauncher implements CoreLauncher {
  final handle = _FakeHandle();
  @override
  Future<CoreHandle> launch(String executable, List<String> arguments) async => handle;
}

class _FakeProxy implements SystemProxyManager {
  var enabled = false;
  var restored = false;
  @override
  Future<void> enable({required String host, required int port}) async => enabled = true;
  @override
  Future<void> restore() async => restored = true;
}

void main() {
  late Directory directory;

  setUp(() => directory = Directory.systemTemp.createTempSync('simorgh-core-test-'));
  tearDown(() => directory.deleteSync(recursive: true));

  test('starts with a temporary config, captures output and restores proxy', () async {
    final binary = File('${directory.path}${Platform.pathSeparator}core.exe')..writeAsStringSync('fake core');
    final launcher = _FakeLauncher();
    final proxy = _FakeProxy();
    final logger = LogService();
    final service = CoreService(logger: logger, launcher: launcher, proxyManager: proxy);
    final result = await service.start(CoreLaunchConfig(binaryPath: binary.path, endpoint: const CoreEndpoint(server: 'relay.test', port: 443, uuid: 'id'), useSystemProxy: true));

    expect(result.isSuccess, isTrue);
    expect(service.state, CoreState.running);
    expect(result.configPath, isNotNull);
    expect(File(result.configPath!).existsSync(), isTrue);
    launcher.handle._stdout.add('core ready\n'.codeUnits);
    await service.stop();
    expect(proxy.enabled, isTrue);
    expect(proxy.restored, isTrue);
    expect(service.state, CoreState.stopped);
    expect(File(result.configPath!).existsSync(), isFalse);
    await logger.dispose();
  });

  test('returns typed failure when the binary is missing', () async {
    final service = CoreService(logger: LogService());
    final result = await service.start(const CoreLaunchConfig(binaryPath: 'missing-core.exe', endpoint: CoreEndpoint(server: 'relay.test', port: 443, uuid: 'id')));
    expect(result.failure, FailureCode.coreMissing);
    expect(service.state, CoreState.failed);
  });
}
