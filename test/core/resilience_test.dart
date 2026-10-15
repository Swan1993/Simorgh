import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:simorgh/core/resilience/config_update_service.dart';
import 'package:simorgh/core/resilience/health_service.dart';

class _Health implements HealthTransport {
  var calls = 0;
  @override
  Future<HealthResult> check(Uri endpoint, {required Duration timeout}) async {
    calls++;
    return HealthResult(healthy: calls > 1, latency: const Duration(milliseconds: 10), statusCode: calls > 1 ? 204 : 503);
  }
}

void main() {
  test('health service reports unhealthy state and reconnect policy retries', () async {
    final transport = _Health();
    var unhealthy = 0;
    final service = HealthService(transport: transport, endpoint: Uri.parse('https://relay.test/health'), onUnhealthy: () => unhealthy++);
    expect((await service.checkOnce()).healthy, isFalse);
    expect((await service.checkOnce()).healthy, isTrue);
    expect(unhealthy, 1);

    var attempts = 0;
    final recovered = await const AutoReconnectPolicy(maxAttempts: 3, initialDelay: Duration.zero).run((_) async {
      attempts++;
      return attempts == 2;
    });
    expect(recovered, isTrue);
    expect(attempts, 2);
  });

  test('config update uses the first source with a valid sha256', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) {
      request.response
        ..statusCode = HttpStatus.ok
        ..write('simorgh-config-v1')
        ..close();
    });
    final url = Uri.parse('http://${server.address.address}:${server.port}/config');
    final service = ConfigUpdateService();
    final result = await service.fetchFirstValid(<ConfigSource>[
      ConfigSource(url: Uri.parse('http://127.0.0.1:1/missing')),
      ConfigSource(url: url, sha256: 'a385179074b7707cba4d95f41787f798149ab709470f0d54bba7fe45d3e5b91c'),
    ]);
    expect(result, 'simorgh-config-v1');
    service.close();
  });
}
