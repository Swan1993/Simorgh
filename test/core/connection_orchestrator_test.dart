import 'package:flutter_test/flutter_test.dart';
import 'package:simorgh/core/connection/connection_orchestrator.dart';
import 'package:simorgh/core/core_service.dart';
import 'package:simorgh/core/logging/log_service.dart';
import 'package:simorgh/core/scanner/ip_range_source.dart';
import 'package:simorgh/core/scanner/ip_scanner.dart';

class _Ranges implements IpRangeSource {
  @override
  Future<List<String>> loadCidrs() async => const <String>['192.0.2.0/30'];
}

class _Probe implements IpProbe {
  @override
  Future<IpProbeResult> probe({required String ip, required List<int> ports, required String serverName, required Duration timeout}) async => IpProbeResult(ip: ip, port: ports.first, status: IpProbeStatus.clean, latencyMs: 3);
}

void main() {
  test('orchestrator reports a typed failure instead of starting a missing core', () async {
    final logger = LogService();
    final core = CoreService(logger: logger);
    final orchestrator = ConnectionOrchestrator(logger: logger, scanner: IpScannerService(probe: _Probe(), rangeSource: _Ranges()), core: core);
    final failure = await orchestrator.connect(scanOptions: const ScanOptions(serverName: 'relay.test', sampleSize: 2, concurrency: 1), coreBinaryPath: 'missing-core.exe', relayServerName: 'relay.test', relayUuid: 'relay-uuid');
    expect(failure, isNotNull);
    await orchestrator.dispose();
    await logger.dispose();
  });
}
