import '../failures/failure_code.dart';
import '../logging/log_entry.dart';

class DebugBundle {
  const DebugBundle({required this.version, required this.stage, required this.failure, required this.logs});
  final String version;
  final String stage;
  final FailureCode failure;
  final List<LogEntry> logs;

  String toMarkdown() => '''## Simorgh Debug Bundle
- Version: $version
- Stage: $stage
- FailureCode: ${failure.wireCode}

### Root cause
${failure.localized().title}

### Evidence
${logs.map((entry) => '- ${entry.toHumanReadable()}').join('\n')}

### Task for IDE
Fix the above issue, identify the responsible service, add a regression test, and update the FailureCode mapping if needed.
''';
}
