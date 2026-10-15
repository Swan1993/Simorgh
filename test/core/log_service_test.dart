import 'package:flutter_test/flutter_test.dart';
import 'package:simorgh/core/logging/log_entry.dart';
import 'package:simorgh/core/logging/log_service.dart';
import 'package:simorgh/core/logging/redactor.dart';

void main() {
  group('LogService', () {
    test('keeps a bounded ring buffer and emits entries to its stream', () async {
      final service = LogService(maxEntries: 2);
      final emitted = <LogEntry>[];
      final subscription = service.stream.listen(emitted.add);

      service.info('scanner', 'first');
      service.warning('scanner', 'second');
      service.error('scanner', 'third', errorCode: 'E_UNKNOWN');

      expect(emitted.map((entry) => entry.message).toList(), <String>[
        'first',
        'second',
        'third',
      ]);
      expect(service.entries.map((entry) => entry.message).toList(), <String>[
        'second',
        'third',
      ]);
      expect(service.entries.first.level, LogLevel.warning);
      expect(service.entries.last.errorCode, 'E_UNKNOWN');

      await subscription.cancel();
      await service.dispose();
    });

    test('redacts structured fields and preserves a JSON representation', () {
      final service = LogService(
        redactor: Redactor(knownSecrets: <String>['secret-value']),
        clock: () => DateTime.utc(2026, 1, 2, 3, 4, 5),
      );

      final entry = service.log(
        level: LogLevel.info,
        component: 'core',
        message: 'received secret-value',
        metadata: <String, Object?>{
          'token': 'secret-value',
          'attempt': 1,
        },
      );

      expect(entry.message, 'received ${Redactor.replacement}');
      expect(entry.metadata['token'], Redactor.replacement);
      expect(entry.metadata['attempt'], 1);
      expect(entry.toJson()['timestamp'], '2026-01-02T03:04:05.000Z');
      expect(entry.toJsonString(), contains('"level":"INFO"'));
      expect(entry.toHumanReadable(), contains('INFO core'));

      return service.dispose();
    });
  });
}
