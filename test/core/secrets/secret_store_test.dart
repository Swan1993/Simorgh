import 'package:flutter_test/flutter_test.dart';
import 'package:simorgh/core/secrets/secret_store.dart';

void main() {
  group('InMemorySecretStore', () {
    test('implements the SecretStore contract', () async {
      await _runSecretStoreContract(InMemorySecretStore());
    });

    test('does not retain empty values', () async {
      final store = InMemorySecretStore();

      await store.write(SecretKeys.aiApiKey, 'initial-secret');
      await store.write(SecretKeys.aiApiKey, '   ');

      expect(await store.read(SecretKeys.aiApiKey), isNull);
    });

    test('rejects an empty key', () async {
      final store = InMemorySecretStore();

      await expectLater(store.read('  '), throwsArgumentError);
      await expectLater(store.write('', 'secret'), throwsArgumentError);
      await expectLater(store.delete('\t'), throwsArgumentError);
    });
  });

  test('defines stable keys for AI and Cloudflare secrets', () {
    expect(SecretKeys.aiApiKey, isNotEmpty);
    expect(SecretKeys.cloudflareApiToken, isNotEmpty);
    expect(SecretKeys.all, containsAll(<String>[
      SecretKeys.aiApiKey,
      SecretKeys.cloudflareApiToken,
    ]));
  });
}

Future<void> _runSecretStoreContract(SecretStore store) async {
  expect(await store.read(SecretKeys.aiApiKey), isNull);

  await store.write(SecretKeys.aiApiKey, 'ai-secret');
  await store.write(SecretKeys.cloudflareApiToken, 'cloudflare-secret');
  expect(await store.read(SecretKeys.aiApiKey), 'ai-secret');
  expect(await store.read(SecretKeys.cloudflareApiToken), 'cloudflare-secret');

  await store.delete(SecretKeys.aiApiKey);
  expect(await store.read(SecretKeys.aiApiKey), isNull);
  expect(await store.read(SecretKeys.cloudflareApiToken), 'cloudflare-secret');

  await store.clear();
  expect(await store.read(SecretKeys.cloudflareApiToken), isNull);
}
