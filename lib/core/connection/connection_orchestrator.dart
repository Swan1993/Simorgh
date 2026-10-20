import 'dart:async';

import '../core_config.dart';
import '../core_service.dart';
import '../diagnostics/debug_bundle.dart';
import '../failures/failure_code.dart';
import '../logging/log_service.dart';
import '../resilience/health_service.dart';
import '../scanner/ip_scanner.dart';

enum OrchestratorStage { idle, preparing, scanning, selectingBest, buildingConfig, startingCore, verifyingConnection, connected, failed }

class OrchestratorEvent {
  const OrchestratorEvent({required this.stage, this.progress = 0, this.scanEvent, this.failure, this.debugBundle});
  final OrchestratorStage stage;
  final int progress;
  final ScanEvent? scanEvent;
  final FailureCode? failure;
  final DebugBundle? debugBundle;
}

class ConnectionOrchestrator {
  ConnectionOrchestrator({required this.logger, required this.scanner, required this.core, HealthService? health, AutoReconnectPolicy? reconnectPolicy}) : _health = health, _reconnectPolicy = reconnectPolicy ?? const AutoReconnectPolicy();
  final LogService logger;
  final IpScannerService scanner;
  final CoreService core;
  final HealthService? _health;
  final AutoReconnectPolicy _reconnectPolicy;
  final StreamController<OrchestratorEvent> _events = StreamController<OrchestratorEvent>.broadcast();
  ScanRun? _activeScan;
  bool _cancelled = false;

  Stream<OrchestratorEvent> get events => _events.stream;

  Future<FailureCode?> connect({required ScanOptions scanOptions, required String coreBinaryPath, required String relayServerName, required String relayUuid, int relayPort = 443, String relayPath = '/', String? expectedCoreSha256, bool useSystemProxy = true, bool verifyLocalPort = false}) async {
    _cancelled = false;
    _emit(const OrchestratorEvent(stage: OrchestratorStage.preparing));
    try {
      _activeScan = scanner.scan(scanOptions);
      await for (final event in _activeScan!.events) {
        if (_cancelled) {
          _activeScan?.cancel();
          return null;
        }
        final stage = event.type == ScanEventType.finished || event.type == ScanEventType.bestChanged ? OrchestratorStage.selectingBest : OrchestratorStage.scanning;
        final progress = event.total == 0 ? 0 : (event.tested * 100 ~/ event.total).clamp(0, 100).toInt();
        _emit(OrchestratorEvent(stage: stage, progress: progress, scanEvent: event));
      }
      final summary = await _activeScan!.done;
      if (_cancelled) {
        return null;
      }
      final best = summary.best;
      if (best == null) return await _fail(FailureCode.allIpsBlocked, 'No clean candidate IP was found.');
      _emit(const OrchestratorEvent(stage: OrchestratorStage.buildingConfig, progress: 80));
      final config = CoreLaunchConfig(binaryPath: coreBinaryPath, expectedSha256: expectedCoreSha256, useSystemProxy: useSystemProxy, verifyLocalPort: verifyLocalPort, endpoint: CoreEndpoint(server: best.ip, serverName: relayServerName, port: relayPort, uuid: relayUuid, path: relayPath));
      _emit(const OrchestratorEvent(stage: OrchestratorStage.startingCore, progress: 88));
      final started = await core.start(config);
      if (_cancelled) {
        await core.stop();
        return null;
      }
      if (!started.isSuccess) return await _fail(started.failure ?? FailureCode.coreCrash, 'Core failed to start.');
      _emit(const OrchestratorEvent(stage: OrchestratorStage.verifyingConnection, progress: 94));
      final result = await _health?.checkOnce();
      if (_cancelled) {
        await core.stop();
        return null;
      }
      if (result != null && !result.healthy) return await _fail(FailureCode.verifyTimeout, 'Health verification failed.');
      _emit(const OrchestratorEvent(stage: OrchestratorStage.connected, progress: 100));
      _health?.start();
      return null;
    } on Object catch (error) {
      return await _fail(FailureCode.unknown, 'Connection flow failed: $error');
    }
  }

  Future<bool> reconnect(Future<bool> Function() attempt) => _reconnectPolicy.run((_) => attempt());

  Future<void> disconnect() async {
    _cancelled = true;
    _health?.stop();
    _activeScan?.cancel();
    await core.stop();
    _emit(const OrchestratorEvent(stage: OrchestratorStage.idle));
  }

  Future<void> dispose() async {
    await disconnect();
    await _events.close();
  }

  Future<FailureCode?> _fail(FailureCode code, String message) async {
    await core.stop();
    logger.error('connection', message, errorCode: code.wireCode);
    final bundle = DebugBundle(version: '0.1.0', stage: 'connection', failure: code, logs: logger.entries);
    _emit(OrchestratorEvent(stage: OrchestratorStage.failed, failure: code, debugBundle: bundle));
    return code;
  }

  void _emit(OrchestratorEvent event) {
    if (!_events.isClosed) _events.add(event);
  }
}
