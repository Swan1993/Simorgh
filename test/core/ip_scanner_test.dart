import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:simorgh/core/scanner/ip_cache.dart';
import 'package:simorgh/core/scanner/ip_range_source.dart';
import 'package:simorgh/core/scanner/ip_scanner.dart';

class _Ranges implements IpRangeSource {
  @override
  Future<List<String>> loadCidrs() async => const <String>['192.0.2.0/30'];
}

class _Probe implements IpProbe {
  @override
  Future<IpProbeResult> probe({required String ip, required List<int> ports, required String serverName, required Duration timeout}) async {
    final last = int.tryParse(ip.split('.').last) ?? 0;
    return IpProbeResult(ip: ip, port: ports.first, status: last.isEven ? IpProbeStatus.clean : IpProbeStatus.blocked, latencyMs: last + 10);
  }
}

void main() {
  test('scanner emits progress, ranks clean IPs and caches the best candidates', () async {
    final directory = Directory.systemTemp.createTempSync('simorgh-scanner-test-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final cache = IpCandidateCache(path: '${directory.path}${Platform.pathSeparator}ips.json');
    final run = IpScannerService(probe: _Probe(), rangeSource: _Ranges(), cache: cache).scan(const ScanOptions(serverName: 'relay.test', sampleSize: 4, concurrency: 2, topK: 2));
    final events = <ScanEvent>[];
    final subscription = run.events.listen(events.add);
    final summary = await run.done;
    await subscription.asFuture<void>();

    expect(summary.cancelled, isFalse);
    expect(summary.clean, isNotEmpty);
    expect(summary.best?.latencyMs, lessThanOrEqualTo(12));
    expect(events.any((event) => event.type == ScanEventType.started), isTrue);
    expect(events.any((event) => event.type == ScanEventType.finished), isTrue);
    expect((await cache.read()).length, 2);
  });

  test('cancel stops scheduling new probes and returns a cancelled summary', () async {
    final gate = Completer<void>();
    final probe = _BlockingProbe(gate);
    final run = IpScannerService(probe: probe, rangeSource: _Ranges()).scan(const ScanOptions(serverName: 'relay.test', sampleSize: 4, concurrency: 1));
    run.cancel();
    gate.complete();
    final summary = await run.done;
    expect(summary.cancelled, isTrue);
  });
}

class _BlockingProbe implements IpProbe {
  _BlockingProbe(this.gate);
  final Completer<void> gate;
  @override
  Future<IpProbeResult> probe({required String ip, required List<int> ports, required String serverName, required Duration timeout}) async {
    await gate.future;
    return IpProbeResult(ip: ip, port: ports.first, status: IpProbeStatus.clean, latencyMs: 1);
  }
}
