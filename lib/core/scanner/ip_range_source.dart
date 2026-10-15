import 'dart:convert';
import 'dart:io';

abstract interface class IpRangeSource {
  Future<List<String>> loadCidrs();
}

class CloudflareIpRangeSource implements IpRangeSource {
  CloudflareIpRangeSource({HttpClient? client, this.fallback = const <String>['104.16.0.0/13', '104.24.0.0/14', '172.64.0.0/13']}) : _client = client ?? HttpClient();

  final HttpClient _client;
  final List<String> fallback;

  @override
  Future<List<String>> loadCidrs() async {
    try {
      final ranges = <String>[];
      for (final url in ['https://www.cloudflare.com/ips-v4', 'https://www.cloudflare.com/ips-v6']) {
        final request = await _client.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 8));
        final response = await request.close().timeout(const Duration(seconds: 8));
        if (response.statusCode != HttpStatus.ok) {
          throw HttpException('Cloudflare range endpoint returned ${response.statusCode}.');
        }
        final body = await response.transform(utf8.decoder).join();
        ranges.addAll(body.split(RegExp(r'\r?\n')).map((line) => line.trim()).where((line) => line.contains('/')));
      }
      if (ranges.isEmpty) {
        throw const FormatException('Cloudflare returned no CIDRs.');
      }
      return List<String>.unmodifiable(ranges);
    } on Object {
      return List<String>.unmodifiable(fallback);
    }
  }

  void close() => _client.close(force: true);
}
