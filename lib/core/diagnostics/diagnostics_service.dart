import '../failures/failure_code.dart';
import '../logging/log_service.dart';
import 'ai_client.dart';
import 'debug_bundle.dart';

class DiagnosticsReport {
  const DiagnosticsReport({required this.failure, required this.ruleBased, this.ai, this.aiError});
  final FailureMessage ruleBased;
  final FailureCode failure;
  final AiDiagnosis? ai;
  final String? aiError;
}

class DiagnosticsService {
  DiagnosticsService({required LogService logger, AiClient? aiClient}) : _logger = logger, _aiClient = aiClient;
  final LogService _logger;
  final AiClient? _aiClient;

  Future<DiagnosticsReport> analyze(DebugBundle bundle, {FailureLanguage language = FailureLanguage.english, bool useAi = false}) async {
    final ruleBased = bundle.failure.localized(language);
    _logger.info('diagnostics', 'Rule-based diagnosis completed.', errorCode: bundle.failure.wireCode);
    if (!useAi || _aiClient == null) return DiagnosticsReport(failure: bundle.failure, ruleBased: ruleBased);
    try {
      final ai = await _aiClient.analyze(bundle);
      _logger.ai('diagnostics', 'AI diagnosis completed.', errorCode: bundle.failure.wireCode);
      return DiagnosticsReport(failure: bundle.failure, ruleBased: ruleBased, ai: ai);
    } on Object catch (error) {
      _logger.warning('diagnostics', 'AI diagnosis failed: $error', errorCode: bundle.failure.wireCode);
      return DiagnosticsReport(failure: bundle.failure, ruleBased: ruleBased, aiError: 'AI analysis unavailable.');
    }
  }
}
