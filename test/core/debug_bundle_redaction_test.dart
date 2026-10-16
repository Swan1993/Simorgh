import 'package:flutter_test/flutter_test.dart';
import 'package:simorgh/core/diagnostics/debug_bundle.dart';
import 'package:simorgh/core/failures/failure_code.dart';
import 'package:simorgh/core/logging/redactor.dart';

void main() {
  test('debug bundle redacts config and network metadata at the export boundary', () {
    final bundle = DebugBundle(
      version: '0.1.0',
      stage: 'verify',
      failure: FailureCode.unknown,
      logs: const [],
      sanitizedConfig: const <String, Object?>{'api_key': 'private-secret'},
      redactor: Redactor(knownSecrets: const <String>['private-secret']),
    );
    final markdown = bundle.toMarkdown();
    expect(markdown, isNot(contains('private-secret')));
    expect(markdown, contains(Redactor.replacement));
  });
}
