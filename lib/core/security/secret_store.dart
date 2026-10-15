import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stable names for values that must never be stored in plain workspace files.
abstract final class SecretKeys {
  static const cloudflareApiToken = 'cloudflare_api_token';
  static const cloudflareAccountId = 'cloudflare_account_id';
  static const aiApiKey = 'ai_api_key';
}

/// Minimal storage contract used by services and easy to replace in tests.
abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> clear();
}

/// In-memory implementation for unit tests and preview mode.
class InMemorySecretStore implements SecretStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    if (key.trim().isEmpty) {
      throw ArgumentError.value(key, 'key', 'Secret key cannot be empty.');
    }
    if (value.isEmpty) {
      await delete(key);
      return;
    }
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> clear() async => _values.clear();
}

/// Platform-backed implementation. On Windows, flutter_secure_storage uses
/// the Windows Credential Manager; other supported platforms use their native
/// secure key store.
class SecureSecretStore implements SecretStore {
  SecureSecretStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) async {
    if (key.trim().isEmpty) {
      throw ArgumentError.value(key, 'key', 'Secret key cannot be empty.');
    }
    if (value.isEmpty) {
      await delete(key);
      return;
    }
    await _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> clear() => _storage.deleteAll();
}
