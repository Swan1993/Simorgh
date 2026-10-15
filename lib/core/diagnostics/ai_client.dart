import 'dart:convert';
import 'dart:io';

import 'debug_bundle.dart';

class AiDiagnosis {
  const AiDiagnosis({required this.rootCause, required this.evidence, required this.suggestedFix, required this.confidence, this.codeChangeHint});
  final String rootCause;
  final List<String> evidence;
  final String suggestedFix;
  final double confidence;
  final String? codeChangeHint;

  static AiDiagnosis? fromJson(Object? value) {
    if (value is! Map) return null;
    final rootCause = value['root_cause'];
    final evidence = value['evidence'];
    final suggestedFix = value['suggested_fix'];
    final confidence = value['confidence'];
    if (rootCause is! String || suggestedFix is! String || confidence is! num) return null;
    return AiDiagnosis(rootCause: rootCause, evidence: evidence is List ? evidence.whereType<String>().toList(growable: false) : const <String>[], suggestedFix: suggestedFix, confidence: confidence.toDouble().clamp(0.0, 1.0).toDouble(), codeChangeHint: value['code_change_hint'] is String ? value['code_change_hint'] as String : null);
  }
}

abstract interface class AiClient {
  Future<AiDiagnosis> analyze(DebugBundle bundle);
}

class OpenAiCompatibleClient implements AiClient {
  OpenAiCompatibleClient({required this.baseUrl, required this.apiKey, required this.model, HttpClient? client}) : _client = client ?? HttpClient();
  final String baseUrl;
  final String apiKey;
  final String model;
  final HttpClient _client;

  @override
  Future<AiDiagnosis> analyze(DebugBundle bundle) async {
    if (apiKey.trim().isEmpty) throw const AiClientException('AI API key is not configured.');
    final endpoint = Uri.parse(baseUrl.endsWith('/') ? '${baseUrl}chat/completions' : '$baseUrl/chat/completions');
    final request = await _client.postUrl(endpoint);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(<String, Object?>{
      'model': model,
      'temperature': 0.1,
      'response_format': <String, String>{'type': 'json_object'},
      'messages': <Object?>[
        <String, String>{'role': 'system', 'content': 'Analyze the redacted diagnostic bundle. Return JSON with root_cause, evidence, suggested_fix, code_change_hint and confidence between 0 and 1.'},
        <String, String>{'role': 'user', 'content': bundle.toMarkdown()},
      ],
    }));
    final response = await request.close().timeout(const Duration(seconds: 30));
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) throw AiClientException('AI endpoint returned HTTP ${response.statusCode}.');
    try {
      final decoded = jsonDecode(text);
      final content = decoded['choices'][0]['message']['content'] as String;
      final diagnosis = AiDiagnosis.fromJson(jsonDecode(_stripCodeFence(content)));
      if (diagnosis == null) throw const AiClientException('AI response did not match the expected schema.');
      return diagnosis;
    } on AiClientException {
      rethrow;
    } on Object catch (error) {
      throw AiClientException('Could not parse AI response: $error');
    }
  }

  String _stripCodeFence(String value) => value.replaceFirst(RegExp(r'^```(?:json)?\s*'), '').replaceFirst(RegExp(r'\s*```$'), '').trim();
  void close() => _client.close(force: true);
}

class AiClientException implements Exception {
  const AiClientException(this.message);
  final String message;
  @override
  String toString() => message;
}
