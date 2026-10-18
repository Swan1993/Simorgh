import 'dart:async';

import '../core_binary_resolver.dart';
import '../core_service.dart';
import '../failures/failure_code.dart';
import '../logging/log_service.dart';
import '../relays/relay_repository.dart';
import '../resilience/health_service.dart';
import '../scanner/ip_scanner.dart';
import 'connection_orchestrator.dart';

enum ConnectionViewStage {
  idle,
  preparing,
  scanning,
  selectingBest,
  buildingConfig,
  startingCore,
  verifyingConnection,
  connected,
  failed,
}

class ConnectionViewState {
  const ConnectionViewState({
    required this.stage,
    this.progress = 0,
    this.testedCount = 0,
    this.totalCount = 0,
    this.cleanCount = 0,
    this.candidates = const <IpProbeResult>[],
    this.selectedIp,
    this.failure,
    this.message,
  });

  final ConnectionViewStage stage;
  final int progress;
  final int testedCount;
  final int totalCount;
  final int cleanCount;
  final List<IpProbeResult> candidates;
  final String? selectedIp;
  final FailureCode? failure;
  final String? message;
  bool get busy =>
      stage != ConnectionViewStage.idle &&
      stage != ConnectionViewStage.connected &&
      stage != ConnectionViewStage.failed;
}

abstract interface class ConnectionSession {
  Stream<ConnectionViewState> get states;
  ConnectionViewState get current;
  Future<void> connect();
  Future<void> disconnect();
  Future<void> dispose();
}

class ProductionConnectionSession implements ConnectionSession {
  ProductionConnectionSession({
    required RelayRepository relays,
    required CoreBinaryResolver binaries,
    required IpScannerService scanner,
    required CoreService core,
    required LogService logger,
  }) : _relays = relays,
       _binaries = binaries,
       _scanner = scanner,
       _core = core,
       _logger = logger;

  final RelayRepository _relays;
  final CoreBinaryResolver _binaries;
  final IpScannerService _scanner;
  final CoreService _core;
  final LogService _logger;
  final StreamController<ConnectionViewState> _states =
      StreamController<ConnectionViewState>.broadcast();
  ConnectionViewState _current = const ConnectionViewState(
    stage: ConnectionViewStage.idle,
  );
  ConnectionOrchestrator? _orchestrator;
  HttpHealthTransport? _healthTransport;
  Future<void>? _connectOperation;
  bool _disposed = false;

  @override
  Stream<ConnectionViewState> get states => _states.stream;

  @override
  ConnectionViewState get current => _current;

  @override
  Future<void> connect() {
    if (_connectOperation != null) return _connectOperation!;
    final operation = _connectInternal();
    _connectOperation = operation;
    return operation.whenComplete(() {
      if (identical(_connectOperation, operation)) _connectOperation = null;
    });
  }

  Future<void> _connectInternal() async {
    if (_disposed || _current.busy) return;
    if (_orchestrator != null) await disconnect();
    final relay = await _relays.active();
    if (relay == null) {
      _emit(
        const ConnectionViewState(
          stage: ConnectionViewStage.failed,
          failure: FailureCode.coreConfigInvalid,
          message: 'No active relay is configured.',
        ),
      );
      return;
    }
    final binary = await _binaries.resolve();
    if (binary == null) {
      _emit(
        const ConnectionViewState(
          stage: ConnectionViewStage.failed,
          failure: FailureCode.coreMissing,
          message:
              'sing-box.exe was not found in the application core directory.',
        ),
      );
      return;
    }

    final serverName = _hostname(relay.hostname);
    final healthEndpoint = Uri.parse('https://$serverName/health');
    final healthTransport = HttpHealthTransport();
    _healthTransport = healthTransport;
    final health = HealthService(
      transport: healthTransport,
      endpoint: healthEndpoint,
      onResult: (result) {
        _logger.info(
          'health',
          'Relay health check completed.',
          metadata: {
            'healthy': result.healthy,
            'latencyMs': result.latency.inMilliseconds,
          },
        );
      },
      onUnhealthy: () {
        _logger.warning('health', 'Relay health check failed.');
        if (!_disposed && _current.stage == ConnectionViewStage.connected) {
          _emit(
            const ConnectionViewState(
              stage: ConnectionViewStage.failed,
              failure: FailureCode.verifyTimeout,
              message: 'Relay health check failed after connection.',
            ),
          );
        }
      },
    );
    final orchestrator = ConnectionOrchestrator(
      logger: _logger,
      scanner: _scanner,
      core: _core,
      health: health,
    );
    _orchestrator = orchestrator;
    final subscription = orchestrator.events.listen(_onOrchestratorEvent);
    try {
      final failure = await orchestrator.connect(
        scanOptions: ScanOptions(
          serverName: serverName,
          ports: <int>[relay.port, 8443, 2053],
          sampleSize: 300,
          concurrency: 40,
        ),
        coreBinaryPath: binary.path,
        expectedCoreSha256: binary.sha256,
        relayServerName: serverName,
        relayUuid: relay.uuid,
        relayPort: relay.port,
        relayPath: relay.path,
        useSystemProxy: true,
        verifyLocalPort: true,
      );
      if (failure != null && _current.stage != ConnectionViewStage.failed) {
        _emit(
          ConnectionViewState(
            stage: ConnectionViewStage.failed,
            failure: failure,
          ),
        );
      }
    } finally {
      await subscription.cancel();
      if (!identical(_orchestrator, orchestrator)) await orchestrator.dispose();
    }
  }

  void _onOrchestratorEvent(OrchestratorEvent event) {
    final candidates = <IpProbeResult>[..._current.candidates];
    final result = event.scanEvent?.result;
    if (result != null) {
      candidates.removeWhere(
        (item) => item.ip == result.ip && item.port == result.port,
      );
      candidates.add(result);
      candidates.sort((a, b) => a.latencyMs.compareTo(b.latencyMs));
    }
    final scanEvent = event.scanEvent;
    _emit(
      ConnectionViewState(
        stage: _stage(event.stage),
        progress: event.progress,
        testedCount: scanEvent?.tested ?? _current.testedCount,
        totalCount: scanEvent?.total ?? _current.totalCount,
        cleanCount: candidates.where((item) => item.isClean).length,
        candidates: candidates,
        selectedIp: scanEvent?.best?.ip ?? _current.selectedIp,
        failure: event.failure,
        message: event.failure?.wireCode,
      ),
    );
  }

  ConnectionViewStage _stage(OrchestratorStage stage) => switch (stage) {
    OrchestratorStage.idle => ConnectionViewStage.idle,
    OrchestratorStage.preparing => ConnectionViewStage.preparing,
    OrchestratorStage.scanning => ConnectionViewStage.scanning,
    OrchestratorStage.selectingBest => ConnectionViewStage.selectingBest,
    OrchestratorStage.buildingConfig => ConnectionViewStage.buildingConfig,
    OrchestratorStage.startingCore => ConnectionViewStage.startingCore,
    OrchestratorStage.verifyingConnection =>
      ConnectionViewStage.verifyingConnection,
    OrchestratorStage.connected => ConnectionViewStage.connected,
    OrchestratorStage.failed => ConnectionViewStage.failed,
  };

  @override
  Future<void> disconnect() async {
    final orchestrator = _orchestrator;
    _orchestrator = null;
    if (orchestrator != null) {
      await orchestrator.disconnect();
      await orchestrator.dispose();
    }
    await _core.stop();
    _healthTransport?.close();
    _healthTransport = null;
    _emit(const ConnectionViewState(stage: ConnectionViewStage.idle));
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await disconnect();
    await _states.close();
  }

  void _emit(ConnectionViewState state) {
    if (_disposed) return;
    _current = state;
    if (!_states.isClosed) _states.add(state);
  }

  String _hostname(String value) {
    final parsed = Uri.tryParse(
      value.contains('://') ? value : 'https://$value',
    );
    return parsed?.host.isNotEmpty == true ? parsed!.host : value;
  }
}
