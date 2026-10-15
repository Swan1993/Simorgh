import 'package:flutter_test/flutter_test.dart';
import 'package:simorgh/core/connection/connection_flow.dart';
import 'package:simorgh/core/failures/failure_code.dart';
import 'package:simorgh/core/logging/log_service.dart';

void main() {
  test('mock connection flow records typed failure', () {
    final logger = LogService();
    final flow = MockConnectionFlow(logger: logger);
    flow.transition(ConnectionStage.scanning, progress: 42);
    flow.fail(FailureCode.sniBlocked, 'SNI was blocked');
    expect(flow.snapshot.stage, ConnectionStage.failed);
    expect(flow.snapshot.failure, FailureCode.sniBlocked);
    expect(logger.entries.last.errorCode, 'E_SNI_BLOCKED');
  });
}
