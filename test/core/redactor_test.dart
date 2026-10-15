import 'package:flutter_test/flutter_test.dart';
import 'package:simorgh/core/logging/redactor.dart';

void main() {
  group('Redactor', () {
    test('hides registered secrets, bearer tokens and URL passwords', () {
      final redactor = Redactor(
        knownSecrets: <String>['cf-live-secret'],
        ownIp: '198.51.100.7',
      );

      final result = redactor.redact(
        'token=cf-live-secret bearer Bearer abc.def.ghi '
        'https://user:password@example.test 198.51.100.7',
      );

      expect(result, isNot(contains('cf-live-secret')));
      expect(result, isNot(contains('abc.def.ghi')));
      expect(result, isNot(contains(':password@')));
      expect(result, isNot(contains('198.51.100.7')));
      expect(result, contains(Redactor.replacement));
    });

    test('masks UUIDs and common API key formats', () {
      final redactor = Redactor();
      final result = redactor.redact(
        'id=550e8400-e29b-41d4-a716-446655440000 '
        'key=sk-1234567890abcdef',
      );

      expect(result, contains(Redactor.uuidReplacement));
      expect(result, contains(Redactor.keyReplacement));
      expect(result, isNot(contains('550e8400-e29b-41d4-a716-446655440000')));
      expect(result, isNot(contains('sk-1234567890abcdef')));
    });

    test('redacts sensitive metadata keys recursively', () {
      final redactor = Redactor(knownSecrets: <String>['nested-secret']);

      final result = redactor.redactMetadata(<String, Object?>{
        'apiKey': 'nested-secret',
        'nested': <String, Object?>{
          'message': 'nested-secret is never shown',
        },
        'count': 3,
      });

      expect(result['apiKey'], Redactor.replacement);
      expect(
        (result['nested']! as Map<String, Object?>)['message'],
        contains(Redactor.replacement),
      );
      expect(result['count'], 3);
    });
  });
}
