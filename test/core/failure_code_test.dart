import 'package:flutter_test/flutter_test.dart';
import 'package:simorgh/core/failures/failure_code.dart';

void main() {
  group('FailureCode', () {
    test('maps every typed code to a stable wire code', () {
      expect(FailureCode.values, hasLength(18));
      final wireCodes = FailureCode.values.map((code) => code.wireCode).toSet();

      expect(wireCodes, hasLength(FailureCode.values.length));
      for (final code in FailureCode.values) {
        expect(code.wireCode, startsWith('E_'));
        expect(FailureCode.fromWireCode(code.wireCode), code);
      }
      expect(FailureCode.fromWireCode('e_dns_fail'), FailureCode.dnsFail);
      expect(FailureCode.fromWireCode('E_NOT_DEFINED'), isNull);
    });

    test('provides title, explanation and fixes in English, Persian and Hindi', () {
      for (final code in FailureCode.values) {
        for (final language in FailureLanguage.values) {
          final message = code.localized(language);
          expect(message.title, isNotEmpty, reason: '${code.wireCode} title');
          expect(
            message.explanation,
            isNotEmpty,
            reason: '${code.wireCode} explanation',
          );
          expect(message.fixes, isNotEmpty, reason: '${code.wireCode} fixes');
        }
      }

      expect(FailureCode.tokenInvalid.messageFor('fa').title, 'توکن API معتبر نیست');
      expect(FailureCode.tokenInvalid.messageFor('hi-IN').title, 'API टोकन अमान्य है');
      expect(FailureCode.tokenInvalid.messageFor('en').title, 'API token is invalid');
    });
  });
}
