import 'package:flutter_test/flutter_test.dart';
import 'package:simorgh/core/security/secret_store.dart';

void main() {
  test('in-memory secret store supports CRUD and empty-value deletion', () async {
    final store = InMemorySecretStore();
    await store.write(SecretKeys.aiApiKey, 'test-secret');
    expect(await store.read(SecretKeys.aiApiKey), 'test-secret');

    await store.write(SecretKeys.aiApiKey, '');
    expect(await store.read(SecretKeys.aiApiKey), isNull);

    await store.write(SecretKeys.cloudflareApiToken, 'token');
    await store.delete(SecretKeys.cloudflareApiToken);
    expect(await store.read(SecretKeys.cloudflareApiToken), isNull);
  });

  test('in-memory secret store rejects an empty key', () async {
    final store = InMemorySecretStore();
    await expectLater(store.write(' ', 'secret'), throwsArgumentError);
  });

  test('clear removes every secret', () async {
    final store = InMemorySecretStore();
    await store.write(SecretKeys.aiApiKey, 'one');
    await store.write(SecretKeys.cloudflareApiToken, 'two');
    await store.clear();
    expect(await store.read(SecretKeys.aiApiKey), isNull);
    expect(await store.read(SecretKeys.cloudflareApiToken), isNull);
  });
}
