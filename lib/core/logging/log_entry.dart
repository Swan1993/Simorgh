import 'dart:convert';

/// Severity used by the structured application log.
enum LogLevel { debug, info, warning, error, ai }

extension LogLevelLabel on LogLevel {
  String get label {
    switch (this) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.ai:
        return 'AI';
    }
  }
}

/// One immutable, structured event emitted by the logging service.
class LogEntry {
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.component,
    required this.message,
    this.errorCode,
    this.metadata = const <String, Object?>{},
  });

  final DateTime timestamp;
  final LogLevel level;
  final String component;
  final String message;
  final String? errorCode;
  final Map<String, Object?> metadata;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'timestamp': timestamp.toUtc().toIso8601String(),
      'level': level.label,
      'component': component,
      'message': message,
      if (errorCode != null) 'errorCode': errorCode,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  String toHumanReadable() {
    final suffix = errorCode == null ? '' : ' [$errorCode]';
    return '${timestamp.toIso8601String()} ${level.label} '
        '$component$suffix: $message';
  }

  @override
  String toString() => toHumanReadable();
}
