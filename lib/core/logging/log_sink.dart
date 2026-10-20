import 'dart:convert';
import 'dart:io';

import 'log_entry.dart';

/// Synchronous sink contract so logging never leaves an unawaited write.
abstract interface class LogSink {
  void append(LogEntry entry);
  void clear();
}

/// JSON-lines persistence with bounded file rotation.
///
/// `path` is supplied by the application; this class never chooses an
/// absolute machine-specific path and never writes secrets because callers
/// provide already-redacted [LogEntry] values.
class RotatingFileLogSink implements LogSink {
  RotatingFileLogSink({required String path, this.maxBytes = 1024 * 1024, this.maxFiles = 3})
    : _file = File(path) {
    if (maxBytes <= 0) {
      throw ArgumentError.value(maxBytes, 'maxBytes');
    }
    if (maxFiles < 1) {
      throw ArgumentError.value(maxFiles, 'maxFiles');
    }
  }

  final File _file;
  final int maxBytes;
  final int maxFiles;

  @override
  void append(LogEntry entry) {
    final line = '${jsonEncode(entry.toJson())}\n';
    _file.parent.createSync(recursive: true);
    final currentLength = _file.existsSync() ? _file.lengthSync() : 0;
    if (currentLength > 0 && currentLength + utf8.encode(line).length > maxBytes) {
      _rotate();
    }
    _file.writeAsStringSync(line, mode: FileMode.append, flush: true);
  }

  void _rotate() {
    for (var index = maxFiles - 1; index >= 1; index--) {
      final oldFile = File('${_file.path}.$index');
      final nextFile = File('${_file.path}.${index + 1}');
      if (oldFile.existsSync()) {
        if (nextFile.existsSync()) {
          nextFile.deleteSync();
        }
        oldFile.renameSync(nextFile.path);
      }
    }
    final firstBackup = File('${_file.path}.1');
    if (firstBackup.existsSync()) {
      firstBackup.deleteSync();
    }
    if (_file.existsSync()) {
      _file.renameSync(firstBackup.path);
    }
  }

  @override
  void clear() {
    if (_file.existsSync()) {
      _file.deleteSync();
    }
    for (var index = 1; index <= maxFiles; index++) {
      final rotated = File('${_file.path}.$index');
      if (rotated.existsSync()) {
        rotated.deleteSync();
      }
    }
  }
}
