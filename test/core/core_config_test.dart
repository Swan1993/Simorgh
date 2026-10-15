import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:simorgh/core/core_config.dart';

void main() {
  const launch = CoreLaunchConfig(
    binaryPath: 'sing-box.exe',
    endpoint: CoreEndpoint(server: 'relay.example.test', port: 443, uuid: 'uuid-1', path: '/edge'),
  );

  test('builds a validated sing-box config with local mixed inbound', () {
    final config = CoreConfigBuilder().build(launch);
    final inbound = (config['inbounds']! as List<Object?>).single as Map<String, Object?>;
    final outbound = (config['outbounds']! as List<Object?>).first as Map<String, Object?>;
    expect(inbound['listen_port'], 10808);
    expect(outbound['server'], 'relay.example.test');
    expect(outbound['server_port'], 443);
    expect(outbound['uuid'], 'uuid-1');
  });

  test('encoded config is valid JSON and rejects invalid ports', () {
    expect(jsonDecode(CoreConfigBuilder().encode(launch)), isA<Map<String, dynamic>>());
    expect(
      () => CoreConfigBuilder().build(const CoreLaunchConfig(binaryPath: 'x', endpoint: CoreEndpoint(server: 'relay', port: 0, uuid: 'id'))),
      throwsArgumentError,
    );
  });
}
