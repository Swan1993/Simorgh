/// Replaces credentials and other sensitive values before they are logged or
/// sent to an external diagnostic service.
class Redactor {
  Redactor({Iterable<String> knownSecrets = const [], String? ownIp}) {
    registerSecrets(knownSecrets);
    if (ownIp != null) {
      registerSecret(ownIp);
    }
  }

  static const String replacement = '<REDACTED>';
  static const String uuidReplacement = replacement;
  static const String keyReplacement = replacement;

  final Set<String> _knownSecrets = <String>{};

  static final RegExp _urlPassword = RegExp(
    r'(https?://[^\s/@:]+:)[^\s/@]+(@)',
    caseSensitive: false,
  );
  static final RegExp _bearerToken = RegExp(
    r'(\bBearer\s+)[A-Za-z0-9._~+/=-]+',
    caseSensitive: false,
  );
  static final RegExp _keyValue = RegExp(
    r'''(["']?(?:api[_-]?key|access[_-]?token|refresh[_-]?token|token|secret|password|passwd|authorization)\b["']?\s*[=:]\s*["']?)[^"'\s,;}&]+''',
    caseSensitive: false,
  );
  static final RegExp _uuid = RegExp(
    r'\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b',
    caseSensitive: false,
  );
  static final RegExp _apiKey = RegExp(
    r'(?<![A-Za-z0-9])(?:sk|rk|pk|xox[baprs]-)[A-Za-z0-9_-]{12,}',
    caseSensitive: false,
  );
  static final RegExp _sensitiveKey = RegExp(
    r'(?:api[_-]?key|access[_-]?token|refresh[_-]?token|token|secret|password|passwd|authorization|private[_-]?key)',
    caseSensitive: false,
  );

  /// Adds a value that must be hidden wherever it appears in a string.
  void registerSecret(String secret) {
    final value = secret.trim();
    if (value.isNotEmpty) {
      _knownSecrets.add(value);
    }
  }

  void registerSecrets(Iterable<String> secrets) {
    for (final secret in secrets) {
      registerSecret(secret);
    }
  }

  /// Returns [input] with known and recognisable secrets replaced.
  String redact(String input) {
    if (input.isEmpty) {
      return input;
    }

    var result = input;
    final secrets = _knownSecrets.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final secret in secrets) {
      result = result.replaceAll(secret, replacement);
    }

    result = result.replaceAllMapped(
      _urlPassword,
      (match) => '${match.group(1)}$replacement${match.group(2)}',
    );
    result = result.replaceAllMapped(
      _bearerToken,
      (match) => '${match.group(1)}$replacement',
    );
    result = result.replaceAllMapped(
      _keyValue,
      (match) => '${match.group(1)}$replacement',
    );
    result = result.replaceAll(_uuid, uuidReplacement);
    result = result.replaceAll(_apiKey, keyReplacement);
    return result;
  }

  /// Recursively redacts strings in metadata while preserving JSON-like types.
  Object? redactValue(Object? value, {String? key}) {
    if (key != null && _sensitiveKey.hasMatch(key)) {
      return replacement;
    }
    if (value is String) {
      return redact(value);
    }
    if (value is Map) {
      return <String, Object?>{
        for (final entry in value.entries)
          entry.key.toString(): redactValue(
            entry.value,
            key: entry.key.toString(),
          ),
      };
    }
    if (value is Iterable) {
      return <Object?>[
        for (final item in value) redactValue(item),
      ];
    }
    return value;
  }

  Map<String, Object?> redactMetadata(Map<String, Object?> metadata) {
    return <String, Object?>{
      for (final entry in metadata.entries)
        entry.key: redactValue(entry.value, key: entry.key),
    };
  }
}
