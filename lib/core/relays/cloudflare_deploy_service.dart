import 'dart:math';

import '../failures/failure_code.dart';
import '../logging/log_service.dart';
import 'cloudflare_api.dart';
import 'relay_models.dart';
import 'worker_template.dart';

class CloudflareDeploymentResult {
  const CloudflareDeploymentResult.success(this.relay) : failure = null;
  const CloudflareDeploymentResult.failure(this.failure) : relay = null;
  final RelayConfig? relay;
  final FailureCode? failure;
  bool get isSuccess => relay != null;
}

class CloudflareDeployService {
  CloudflareDeployService({required CloudflareApi api, required LogService logger, Random? random}) : _api = api, _logger = logger, _random = random ?? Random.secure();
  final CloudflareApi _api;
  final LogService _logger;
  final Random _random;

  Future<CloudflareDeploymentResult> deploy(CloudflareDeployRequest request) async {
    try {
      final validation = _validate(request);
      if (validation != null) return _fail(validation, 'Deployment input is invalid.');
      _logger.info('cloudflare', 'Validating API token for relay deployment.');
      final verification = await _api.get('/user/tokens/verify', apiToken: request.apiToken);
      if (!verification.ok) return _fail(FailureCode.tokenInvalid, 'Cloudflare API token verification failed.');

      final scriptName = request.scriptName.trim();
      final path = '/${_randomSegment(24)}';
      final uuid = _uuid();
      final script = _workerScript(path, uuid, request.workerScript ?? defaultRelayWorkerScript);
      _logger.info('cloudflare', 'Uploading Worker script.', metadata: {'scriptName': scriptName});
      final upload = await _api.putWorkerScript('/accounts/${request.accountId.trim()}/workers/scripts/$scriptName', apiToken: request.apiToken, script: script);
      if (!upload.ok) return _fail(FailureCode.workerBlockedByCloudflare, 'Cloudflare rejected the Worker deployment.');

      final hostname = _hostname(upload.result, scriptName);
      final relay = RelayConfig(id: _randomSegment(16), name: request.name.trim(), hostname: hostname, uuid: uuid, path: path);
      _logger.info('cloudflare', 'Worker relay deployed.', metadata: {'relayId': relay.id, 'hostname': relay.hostname});
      return CloudflareDeploymentResult.success(relay);
    } on Object catch (error) {
      return _fail(FailureCode.workerBlockedByCloudflare, 'Cloudflare deployment request failed: $error');
    }
  }

  FailureCode? _validate(CloudflareDeployRequest request) {
    if (request.apiToken.trim().isEmpty) return FailureCode.tokenInvalid;
    final scriptName = request.scriptName.trim();
    if (request.accountId.trim().isEmpty || scriptName.isEmpty || request.name.trim().isEmpty) return FailureCode.coreConfigInvalid;
    if (!_isValidScriptName(scriptName)) return FailureCode.coreConfigInvalid;
    return null;
  }

  bool _isValidScriptName(String value) {
    if (value.length > 63) return false;
    return value.codeUnits.every((code) => code == 45 || code == 95 || code >= 48 && code <= 57 || code >= 65 && code <= 90 || code >= 97 && code <= 122);
  }

  CloudflareDeploymentResult _fail(FailureCode code, String message) {
    _logger.error('cloudflare', message, errorCode: code.wireCode);
    return CloudflareDeploymentResult.failure(code);
  }

  String _workerScript(String path, String uuid, String template) => template.replaceAll('__SIMORGH_PATH__', path).replaceAll('__SIMORGH_UUID__', uuid);

  String _hostname(Object? result, String scriptName) {
    if (result is Map && result['url'] is String && (result['url'] as String).isNotEmpty) {
      final value = result['url'] as String;
      final parsed = Uri.tryParse(value.contains('://') ? value : 'https://$value');
      if (parsed?.host.isNotEmpty == true) return parsed!.host;
    }
    return '$scriptName.workers.dev';
  }

  String _randomSegment(int length) {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(List<int>.generate(length, (_) => alphabet.codeUnitAt(_random.nextInt(alphabet.length))));
  }

  String _uuid() {
    final values = List<int>.generate(16, (_) => _random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40;
    values[8] = (values[8] & 0x3f) | 0x80;
    final hex = values.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
