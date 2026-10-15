import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'ip_cache.dart';
import 'ip_range_source.dart';

enum IpProbeStatus { clean, blocked, timeout, error }

class IpProbeResult {
  const IpProbeResult({required this.ip, required this.port, required this.status, required this.latencyMs, this.error});
  final String ip;
  final int port;
  final IpProbeStatus status;
  final int latencyMs;
  final String? error;
  bool get isClean => status == IpProbeStatus.clean;
}

abstract interface class IpProbe {
  Future<IpProbeResult> probe({required String ip, required List<int> ports, required String serverName, required Duration timeout});
}

class SocketTlsProbe implements IpProbe {
  @override
  Future<IpProbeResult> probe({required String ip, required List<int> ports, required String serverName, required Duration timeout}) async {
    IpProbeResult? lastFailure;
    for (final port in ports) {
      final stopwatch = Stopwatch()..start();
      Socket? socket;
      try {
        socket = await Socket.connect(ip, port, timeout: timeout);
        final secure = await SecureSocket.secure(socket, host: serverName).timeout(timeout);
        await secure.close();
        stopwatch.stop();
        return IpProbeResult(ip: ip, port: port, status: IpProbeStatus.clean, latencyMs: stopwatch.elapsedMilliseconds);
      } on TimeoutException catch (error) {
        stopwatch.stop();
        lastFailure = IpProbeResult(ip: ip, port: port, status: IpProbeStatus.timeout, latencyMs: stopwatch.elapsedMilliseconds, error: '$error');
      } on Object catch (error) {
        stopwatch.stop();
        lastFailure = IpProbeResult(ip: ip, port: port, status: IpProbeStatus.blocked, latencyMs: stopwatch.elapsedMilliseconds, error: '$error');
      } finally {
        socket?.destroy();
      }
    }
    return lastFailure ?? IpProbeResult(ip: ip, port: ports.first, status: IpProbeStatus.error, latencyMs: 0, error: 'No ports configured.');
  }
}

class ScanOptions {
  const ScanOptions({this.cidrs = const <String>[], required this.serverName, this.ports = const <int>[443, 8443, 2053, 2083, 2087, 2096], this.sampleSize = 300, this.concurrency = 40, this.timeout = const Duration(seconds: 3), this.topK = 15, this.randomSeed = 7});
  final List<String> cidrs;
  final String serverName;
  final List<int> ports;
  final int sampleSize;
  final int concurrency;
  final Duration timeout;
  final int topK;
  final int randomSeed;
}

enum ScanEventType { started, phaseChanged, ipTested, bestChanged, finished, cancelled }

class ScanEvent {
  const ScanEvent({required this.type, this.phase, this.result, this.best, this.tested = 0, this.total = 0});
  final ScanEventType type;
  final String? phase;
  final IpProbeResult? result;
  final IpProbeResult? best;
  final int tested;
  final int total;
}

class ScanSummary {
  const ScanSummary({required this.results, required this.cancelled});
  final List<IpProbeResult> results;
  final bool cancelled;
  List<IpProbeResult> get clean => results.where((item) => item.isClean).toList(growable: false);
  IpProbeResult? get best => ScanRanker.rank(clean).firstOrNull;
}

class ScanRun {
  ScanRun(this.events, this.done, this.cancel);
  final Stream<ScanEvent> events;
  final Future<ScanSummary> done;
  final void Function() cancel;
}

class IpScannerService {
  IpScannerService({IpProbe? probe, IpRangeSource? rangeSource, IpCandidateCache? cache, Random? random}) : _probe = probe ?? SocketTlsProbe(), _rangeSource = rangeSource ?? CloudflareIpRangeSource(), _cache = cache, _random = random;
  final IpProbe _probe;
  final IpRangeSource _rangeSource;
  final IpCandidateCache? _cache;
  final Random? _random;

  ScanRun scan(ScanOptions options) {
    final controller = StreamController<ScanEvent>.broadcast();
    final completer = Completer<ScanSummary>();
    var cancelled = false;
    void cancel() => cancelled = true;
    unawaited(_run(options, controller, completer, () => cancelled));
    return ScanRun(controller.stream, completer.future, cancel);
  }

  Future<void> _run(ScanOptions options, StreamController<ScanEvent> events, Completer<ScanSummary> done, bool Function() isCancelled) async {
    final results = <IpProbeResult>[];
    try {
      final cidrs = options.cidrs.isEmpty ? await _rangeSource.loadCidrs() : options.cidrs;
      final ips = _sampleIps(cidrs, options.sampleSize, options.randomSeed);
      events.add(ScanEvent(type: ScanEventType.started, phase: 'prepare', total: ips.length));
      events.add(ScanEvent(type: ScanEventType.phaseChanged, phase: 'scanIps', total: ips.length));
      var cursor = 0;
      IpProbeResult? best;
      Future<void> worker() async {
        while (!isCancelled()) {
          if (cursor >= ips.length) return;
          final ip = ips[cursor++];
          final result = await _probe.probe(ip: ip, ports: options.ports, serverName: options.serverName, timeout: options.timeout);
          results.add(result);
          final currentBest = ScanRanker.rank(results.where((item) => item.isClean)).firstOrNull;
          if (currentBest != null && (best == null || currentBest.ip != best!.ip || currentBest.latencyMs != best!.latencyMs)) {
            best = currentBest;
            events.add(ScanEvent(type: ScanEventType.bestChanged, best: best, result: result, tested: results.length, total: ips.length));
          }
          events.add(ScanEvent(type: ScanEventType.ipTested, result: result, best: best, tested: results.length, total: ips.length));
        }
      }
      final workerCount = min(max(options.concurrency, 1), max(ips.length, 1));
      await Future.wait(List<Future<void>>.generate(workerCount, (_) => worker()));
      if (isCancelled()) {
        events.add(ScanEvent(type: ScanEventType.cancelled, tested: results.length, total: ips.length));
      } else {
        final ranked = ScanRanker.rank(results.where((item) => item.isClean)).take(options.topK).toList(growable: false);
        if (_cache != null) {
          await _cache!.write(ranked.map((item) => CachedIp(ip: item.ip, latencyMs: item.latencyMs, savedAt: DateTime.now())));
        }
        events.add(ScanEvent(type: ScanEventType.finished, phase: 'finished', best: ranked.firstOrNull, tested: results.length, total: ips.length));
      }
      done.complete(ScanSummary(results: List<IpProbeResult>.unmodifiable(results), cancelled: isCancelled()));
    } on Object {
      done.complete(ScanSummary(results: List<IpProbeResult>.unmodifiable(results), cancelled: isCancelled()));
    } finally {
      await events.close();
    }
  }

  List<String> _sampleIps(List<String> cidrs, int requested, int seed) {
    final random = _random ?? Random(seed);
    final values = <String>{};
    var attempts = 0;
    while (values.length < max(requested, 0) && attempts < max(requested * 20, 20)) {
      attempts++;
      final cidr = cidrs[random.nextInt(cidrs.length)];
      final parts = cidr.split('/');
      if (parts.length != 2) continue;
      final address = InternetAddress.tryParse(parts[0]);
      final prefix = int.tryParse(parts[1]);
      if (address == null || prefix == null || prefix < 0 || prefix > address.rawAddress.length * 8) continue;
      final bytes = List<int>.from(address.rawAddress);
      for (var bit = prefix; bit < bytes.length * 8; bit++) {
        final byte = bit ~/ 8;
        final mask = 1 << (7 - bit % 8);
        if (random.nextBool()) bytes[byte] |= mask;
        else bytes[byte] &= ~mask;
      }
      values.add(InternetAddress.fromRawAddress(bytes).address);
    }
    return values.toList(growable: false);
  }
}

class ScanRanker {
  const ScanRanker._();
  static List<IpProbeResult> rank(Iterable<IpProbeResult> values) {
    final ranked = values.where((item) => item.isClean).toList();
    ranked.sort((a, b) => a.latencyMs.compareTo(b.latencyMs));
    return ranked;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
