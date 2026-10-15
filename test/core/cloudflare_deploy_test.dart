import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:simorgh/core/logging/log_service.dart';
import 'package:simorgh/core/relays/cloudflare_api.dart';
import 'package:simorgh/core/relays/cloudflare_deploy_service.dart';
import 'package:simorgh/core/relays/relay_models.dart';
import 'package:simorgh/core/relays/relay_repository.dart';
import 'package:simorgh/core/security/secret_store.dart';

class _Api implements CloudflareApi {
  String? uploadedScript;
  @override
  Future<CloudflareResponse> get(String path, {required String apiToken}) async => const CloudflareResponse(statusCode: 200, success: true, result: <String, Object?>{});
  @override
  Future<CloudflareResponse> putWorkerScript(String path, {required String apiToken, required String script}) async {
    uploadedScript = script;
    return const CloudflareResponse(statusCode: 200, success: true, result: <String, Object?>{'url': 'relay.workers.dev'});
  }
}

void main() {
  test('deploy validates token, uploads a worker and returns relay credentials', () async {
    final api = _Api();
    final logger = LogService();
    final service = CloudflareDeployService(api: api, logger: logger);
    final result = await service.deploy(const CloudflareDeployRequest(apiToken: 'private-token', accountId: 'account', scriptName: 'simorgh-relay', name: 'Primary'));
    expect(result.isSuccess, isTrue);
    expect(result.relay!.hostname, 'relay.workers.dev');
    expect(result.relay!.uuid, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(api.uploadedScript, contains('EXPECTED_PATH'));
    expect(logger.entries.map((entry) => entry.message).join(), isNot(contains('private-token')));
    await logger.dispose();
  });

  test('relay repository keeps uuid and path out of metadata files', () async {
    final directory = Directory.systemTemp.createTempSync('simorgh-relay-test-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final secrets = InMemorySecretStore();
    final repository = RelayRepository(metadataPath: '${directory.path}${Platform.pathSeparator}relays.json', secrets: secrets);
    final relay = RelayConfig(id: 'relay-1', name: 'Primary', hostname: 'relay.workers.dev', uuid: 'uuid-secret', path: '/path-secret');
    await repository.save(relay);
    final metadata = await File('${directory.path}${Platform.pathSeparator}relays.json').readAsString();
    expect(metadata, isNot(contains('uuid-secret')));
    expect(metadata, isNot(contains('path-secret')));
    expect((await repository.list()).single.uuid, 'uuid-secret');
    await repository.setActive('relay-1');
    expect((await repository.list()).single.active, isTrue);
  });
}
