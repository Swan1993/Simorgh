import 'package:get_x_storage_secure/get_x_storage_secure.dart';

/// Stable names for values that must never be stored in plain workspace files.
abstract final class SecretKeys {
  static const cloudflareApiToken = 'cloudflare_api_token';
  static const cloudflareAccountId = 'cloudflare_account_id';
  static const aiApiKey = 'ai_api_key';
  static const all = <String>[
    cloudflareApiToken,
    cloudflareAccountId,
    aiApiKey,
  ];
}

abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> clear();
}

class InMemorySecretStore implements SecretStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async {
    _validateKey(key);
    return _values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _validateKey(key);
    if (value.trim().isEmpty) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
  }

  @override
  Future<void> delete(String key) async {
    _validateKey(key);
    _values.remove(key);
  }

  @override
  Future<void> clear() async => _values.clear();
}

/// Uses the platform-native secret store through get_x_storage_secure. On
/// Windows its backend is user-scoped DPAPI. It intentionally exposes no
/// logging hooks.
class SecureSecretStore implements SecretStore {
  SecureSecretStore({SecureStorage? storage})
    : _storage = storage ?? SecureStorage(namespace: 'simorgh');

  final SecureStorage _storage;

  @override
  Future<String?> read(String key) async {
    _validateKey(key);
    final value = await _storage.read(key);
    return value == null || value.trim().isEmpty ? null : value;
  }

  @override
  Future<void> write(String key, String value) async {
    _validateKey(key);
    if (value.trim().isEmpty) {
      await delete(key);
      return;
    }
    await _storage.write(key, value);
  }

  @override
  Future<void> delete(String key) async {
    _validateKey(key);
    await _storage.delete(key);
  }

  @override
  Future<void> clear() => _storage.deleteAll();
}

void _validateKey(String key) {
  if (key.trim().isEmpty) {
    throw ArgumentError.value(key, 'key', 'Secret key cannot be empty.');
  }
}
