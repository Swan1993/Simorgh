import 'dart:async';

import 'log_entry.dart';
import 'redactor.dart';
import 'log_sink.dart';

/// In-memory structured logger with a bounded history and a live stream.
///
/// Persistence and file rotation can be layered on top later without changing
/// callers: every emitted entry is already redacted and JSON serialisable.
class LogService {
  LogService({
    Redactor? redactor,
    this.maxEntries = 5000,
    LogSink? sink,
    DateTime Function()? clock,
  }) : assert(maxEntries > 0, 'maxEntries must be greater than zero'),
        _redactor = redactor ?? Redactor(),
        _sink = sink,
        _clock = clock ?? DateTime.now {
    if (maxEntries <= 0) {
      throw ArgumentError.value(maxEntries, 'maxEntries');
    }
  }

  final int maxEntries;
  final Redactor _redactor;
  final LogSink? _sink;
  final DateTime Function() _clock;
  final List<LogEntry> _entries = <LogEntry>[];
  final StreamController<LogEntry> _controller =
      StreamController<LogEntry>.broadcast(sync: true);
  bool _disposed = false;

  Redactor get redactor => _redactor;
  Stream<LogEntry> get stream => _controller.stream;
  Stream<LogEntry> get entriesStream => stream;
  List<LogEntry> get entries => List<LogEntry>.unmodifiable(_entries);
  List<LogEntry> get logs => entries;

  LogEntry log({
    required LogLevel level,
    required String component,
    required String message,
    String? errorCode,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    if (_disposed) {
      throw StateError('LogService has been disposed');
    }

    final entry = LogEntry(
      timestamp: _clock(),
      level: level,
      component: _redactor.redact(component),
      message: _redactor.redact(message),
      errorCode: errorCode,
      metadata: Map<String, Object?>.unmodifiable(
        _redactor.redactMetadata(metadata),
      ),
    );
    _entries.add(entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }
    _controller.add(entry);
    // A logging failure must never take down the connection flow. The entry
    // remains available in memory even if a disk/permission issue occurs.
    try {
      _sink?.append(entry);
    } on Object {
      // Intentionally ignored; callers can still inspect the in-memory ring.
    }
    return entry;
  }

  LogEntry debug(
    String component,
    String message, {
    String? errorCode,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) => log(
    level: LogLevel.debug,
    component: component,
    message: message,
    errorCode: errorCode,
    metadata: metadata,
  );

  LogEntry info(
    String component,
    String message, {
    String? errorCode,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) => log(
    level: LogLevel.info,
    component: component,
    message: message,
    errorCode: errorCode,
    metadata: metadata,
  );

  LogEntry warning(
    String component,
    String message, {
    String? errorCode,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) => log(
    level: LogLevel.warning,
    component: component,
    message: message,
    errorCode: errorCode,
    metadata: metadata,
  );

  LogEntry error(
    String component,
    String message, {
    String? errorCode,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) => log(
    level: LogLevel.error,
    component: component,
    message: message,
    errorCode: errorCode,
    metadata: metadata,
  );

  LogEntry ai(
    String component,
    String message, {
    String? errorCode,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) => log(
    level: LogLevel.ai,
    component: component,
    message: message,
    errorCode: errorCode,
    metadata: metadata,
  );

  void clear() {
    _entries.clear();
    try {
      _sink?.clear();
    } on Object {
      // Intentionally ignored for the same reason as append failures.
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _controller.close();
  }
}
