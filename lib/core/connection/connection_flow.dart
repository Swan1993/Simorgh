import '../failures/failure_code.dart';
import '../logging/log_service.dart';

enum ConnectionStage { idle, preparing, scanning, selectingBest, buildingConfig, startingCore, verifyingConnection, connected, failed }

class ConnectionSnapshot {
  const ConnectionSnapshot({required this.stage, this.progress = 0, this.failure});
  final ConnectionStage stage;
  final int progress;
  final FailureCode? failure;
  bool get isBusy => stage == ConnectionStage.preparing || stage == ConnectionStage.scanning || stage == ConnectionStage.selectingBest || stage == ConnectionStage.buildingConfig || stage == ConnectionStage.startingCore || stage == ConnectionStage.verifyingConnection;
}

class MockConnectionFlow {
  MockConnectionFlow({required this.logger});
  final LogService logger;
  ConnectionSnapshot snapshot = const ConnectionSnapshot(stage: ConnectionStage.idle);

  void transition(ConnectionStage stage, {int progress = 0, FailureCode? failure}) {
    snapshot = ConnectionSnapshot(stage: stage, progress: progress, failure: failure);
    logger.info('connection', 'Stage changed to ${stage.name}', errorCode: failure?.wireCode, metadata: {'progress': progress});
  }

  void fail(FailureCode code, String reason) {
    transition(ConnectionStage.failed, failure: code);
    logger.error('connection', reason, errorCode: code.wireCode);
  }
}
