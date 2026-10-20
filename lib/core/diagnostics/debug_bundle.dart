import 'dart:convert';

import '../failures/failure_code.dart';
import '../logging/log_entry.dart';
import '../logging/redactor.dart';

class DebugBundle {
  const DebugBundle({
    required this.version,
    required this.stage,
    required this.failure,
    required this.logs,
    this.connectionMode = 'system-proxy',
    this.scanSummary = const <String, Object?>{},
    this.sanitizedConfig = const <String, Object?>{},
    this.networkChecks = const <String, Object?>{},
    this.coreStderrTail = const <String>[],
    this.redactor,
  });
  final String version;
  final String stage;
  final FailureCode failure;
  final List<LogEntry> logs;
  final String connectionMode;
  final Map<String, Object?> scanSummary;
  final Map<String, Object?> sanitizedConfig;
  final Map<String, Object?> networkChecks;
  final List<String> coreStderrTail;
  final Redactor? redactor;

  String toMarkdown({Redactor? overrideRedactor}) =>
      '''## Simorgh Debug Bundle
- Version: $version
- Stage: $stage
- Mode: $connectionMode
- FailureCode: ${failure.wireCode}

### Root cause
${failure.localized().title}

### Evidence
${logs.map((entry) => '- ${entry.toHumanReadable()}').join('\n')}

### Scan summary
${_safe(scanSummary, overrideRedactor)}

### Sanitized config
${_safe(sanitizedConfig, overrideRedactor)}

### Network checks
${_safe(networkChecks, overrideRedactor)}

### Core stderr tail
${_safe(coreStderrTail, overrideRedactor)}

### Task for IDE
Fix the above issue, identify the responsible service, add a regression test, and update the FailureCode mapping if needed.
''';

  String _safe(Object value, Redactor? overrideRedactor) {
    if (value is Map && value.isEmpty || value is Iterable && value.isEmpty) {
      return 'Not available';
    }
    final encoded = jsonEncode(value);
    return (overrideRedactor ?? redactor)?.redact(encoded) ?? encoded;
  }
}
