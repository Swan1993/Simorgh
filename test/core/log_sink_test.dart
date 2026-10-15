import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:simorgh/core/logging/log_entry.dart';
import 'package:simorgh/core/logging/log_service.dart';
import 'package:simorgh/core/logging/log_sink.dart';
import 'package:simorgh/core/logging/redactor.dart';

void main() {
  late Directory directory;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('simorgh-log-test-');
  });

  tearDown(() {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });

  test('persists redacted structured logs and rotates files', () async {
    final path = '${directory.path}${Platform.pathSeparator}simorgh.jsonl';
    final sink = RotatingFileLogSink(path: path, maxBytes: 220, maxFiles: 2);
    final logger = LogService(
      redactor: Redactor(knownSecrets: <String>['private-token']),
      sink: sink,
    );

    logger.info('test', 'token=private-token');
    logger.error('test', 'second entry with enough text to rotate the file');
    logger.warning('test', 'third entry with enough text to rotate the file');
    await logger.dispose();

    final current = File(path);
    expect(current.existsSync(), isTrue);
    expect(current.readAsStringSync(), isNot(contains('private-token')));
    expect(File('$path.1').existsSync(), isTrue);
  });

  test('clear removes current and rotated files', () {
    final path = '${directory.path}${Platform.pathSeparator}simorgh.jsonl';
    final sink = RotatingFileLogSink(path: path, maxBytes: 80, maxFiles: 2);
    final logger = LogService(sink: sink);
    logger.info('test', 'first entry with enough text for rotation');
    logger.info('test', 'second entry with enough text for rotation');
    logger.clear();
    expect(File(path).existsSync(), isFalse);
    expect(File('$path.1').existsSync(), isFalse);
  });

  test('sink serializes the same structured entry as LogEntry', () {
    final entry = LogEntry(
      timestamp: DateTime.utc(2026, 1, 1),
      level: LogLevel.info,
      component: 'test',
      message: 'hello',
    );
    final path = '${directory.path}${Platform.pathSeparator}one.jsonl';
    final sink = RotatingFileLogSink(path: path);
    sink.append(entry);
    expect(File(path).readAsStringSync(), contains('"level":"INFO"'));
  });
}
