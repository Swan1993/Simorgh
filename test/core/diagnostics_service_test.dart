import 'package:flutter_test/flutter_test.dart';
import 'package:simorgh/core/diagnostics/ai_client.dart';
import 'package:simorgh/core/diagnostics/debug_bundle.dart';
import 'package:simorgh/core/diagnostics/diagnostics_service.dart';
import 'package:simorgh/core/failures/failure_code.dart';
import 'package:simorgh/core/logging/log_service.dart';

class _Ai implements AiClient {
  @override
  Future<AiDiagnosis> analyze(DebugBundle bundle) async => const AiDiagnosis(rootCause: 'SNI filtering', evidence: <String>['RST'], suggestedFix: 'Switch relay', confidence: 0.94);
}

void main() {
  test('diagnostics returns localized deterministic diagnosis before AI', () async {
    final logger = LogService();
    final service = DiagnosticsService(logger: logger, aiClient: _Ai());
    final bundle = DebugBundle(version: '0.1.0', stage: 'verify', failure: FailureCode.sniBlocked, logs: logger.entries);
    final report = await service.analyze(bundle, language: FailureLanguage.persian);
    expect(report.ai, isNull);
    expect(report.ruleBased.title, contains('SNI'));
    await logger.dispose();
  });

  test('AI diagnosis is optional and failures are safe', () async {
    final logger = LogService();
    final service = DiagnosticsService(logger: logger, aiClient: _Ai());
    final bundle = const DebugBundle(
      version: '0.1.0',
      stage: 'verify',
      failure: FailureCode.verifyTimeout,
      logs: [],
    );
    final report = await service.analyze(bundle, useAi: true);
    expect(report.ai?.confidence, 0.94);
    expect(bundle.toMarkdown(), contains('E_VERIFY_TIMEOUT'));
    await logger.dispose();
  });

  test('AI response parser clamps confidence and accepts evidence', () {
    final diagnosis = AiDiagnosis.fromJson(<String, Object?>{'root_cause': 'x', 'evidence': <String>['a'], 'suggested_fix': 'y', 'confidence': 4});
    expect(diagnosis?.confidence, 1.0);
  });
}
