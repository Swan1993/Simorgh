import 'dart:convert';
import 'dart:io';

class CloudflareResponse {
  const CloudflareResponse({required this.statusCode, required this.success, this.result, this.errors = const <Object?>[]});
  final int statusCode;
  final bool success;
  final Object? result;
  final List<Object?> errors;
  bool get ok => statusCode >= 200 && statusCode < 300 && success;
}

abstract interface class CloudflareApi {
  Future<CloudflareResponse> get(String path, {required String apiToken});
  Future<CloudflareResponse> putWorkerScript(String path, {required String apiToken, required String script});
}

class HttpCloudflareApi implements CloudflareApi {
  HttpCloudflareApi({HttpClient? client, Uri? baseUri}) : _client = client ?? HttpClient(), _baseUri = baseUri ?? Uri.parse('https://api.cloudflare.com/client/v4/');
  final HttpClient _client;
  final Uri _baseUri;

  @override
  Future<CloudflareResponse> get(String path, {required String apiToken}) => _request('GET', path, apiToken: apiToken);

  @override
  Future<CloudflareResponse> putWorkerScript(String path, {required String apiToken, required String script}) => _request('PUT', path, apiToken: apiToken, body: script, contentType: 'application/javascript');

  Future<CloudflareResponse> _request(String method, String path, {required String apiToken, String? body, String contentType = 'application/json'}) async {
    final uri = _baseUri.resolve(path.startsWith('/') ? path.substring(1) : path);
    final request = await _client.openUrl(method, uri);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiToken');
    request.headers.contentType = ContentType.parse(contentType);
    if (body != null) request.write(body);
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (contentType == 'application/javascript') {
      return CloudflareResponse(statusCode: response.statusCode, success: response.statusCode >= 200 && response.statusCode < 300, result: text);
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        return CloudflareResponse(statusCode: response.statusCode, success: decoded['success'] == true, result: decoded['result'], errors: decoded['errors'] is List ? List<Object?>.from(decoded['errors'] as List) : const <Object?>[]);
      }
    } on FormatException {
      // Fall through to a failed structured response.
    }
    return CloudflareResponse(statusCode: response.statusCode, success: false, errors: <Object?>[text]);
  }

  void close() => _client.close(force: true);
}
