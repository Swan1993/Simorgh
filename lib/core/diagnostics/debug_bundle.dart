import '../failures/failure_code.dart';
import '../logging/log_entry.dart';

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

  String toMarkdown() =>
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
${scanSummary.isEmpty ? 'Not available' : scanSummary}

### Sanitized config
${sanitizedConfig.isEmpty ? 'Not available' : sanitizedConfig}

### Network checks
${networkChecks.isEmpty ? 'Not available' : networkChecks}

### Core stderr tail
${coreStderrTail.isEmpty ? 'Not available' : coreStderrTail.join('\n')}

### Task for IDE
Fix the above issue, identify the responsible service, add a regression test, and update the FailureCode mapping if needed.
''';
}
