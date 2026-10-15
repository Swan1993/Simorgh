import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

class ConfigSource {
  const ConfigSource({required this.url, this.sha256});
  final Uri url;
  final String? sha256;
}

class ConfigUpdateService {
  ConfigUpdateService({HttpClient? client}) : _client = client ?? HttpClient();
  final HttpClient _client;

  Future<String?> fetchFirstValid(Iterable<ConfigSource> sources, {Duration timeout = const Duration(seconds: 10)}) async {
    for (final source in sources) {
      try {
        final request = await _client.getUrl(source.url).timeout(timeout);
        final response = await request.close().timeout(timeout);
        if (response.statusCode != HttpStatus.ok) continue;
        final bytes = await response.fold<List<int>>(<int>[], (buffer, chunk) => buffer..addAll(chunk));
        if (source.sha256 != null && sha256.convert(bytes).toString().toLowerCase() != source.sha256!.toLowerCase()) continue;
        return utf8.decode(bytes);
      } on Object {
        // Try the next configured fallback source.
      }
    }
    return null;
  }

  void close() => _client.close(force: true);
}
