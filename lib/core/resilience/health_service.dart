import 'dart:async';
import 'dart:io';

class HealthResult {
  const HealthResult({required this.healthy, required this.latency, this.statusCode, this.error});
  final bool healthy;
  final Duration latency;
  final int? statusCode;
  final String? error;
}

abstract interface class HealthTransport {
  Future<HealthResult> check(Uri endpoint, {required Duration timeout});
}

class HttpHealthTransport implements HealthTransport {
  HttpHealthTransport({HttpClient? client}) : _client = client ?? HttpClient();
  final HttpClient _client;

  @override
  Future<HealthResult> check(Uri endpoint, {required Duration timeout}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final request = await _client.getUrl(endpoint).timeout(timeout);
      final response = await request.close().timeout(timeout);
      await response.drain<void>();
      return HealthResult(healthy: response.statusCode >= 200 && response.statusCode < 400, latency: stopwatch.elapsed, statusCode: response.statusCode);
    } on Object catch (error) {
      return HealthResult(healthy: false, latency: stopwatch.elapsed, error: '$error');
    }
  }

  void close() => _client.close(force: true);
}

class HealthService {
  HealthService({required HealthTransport transport, required Uri endpoint, this.interval = const Duration(seconds: 30), this.timeout = const Duration(seconds: 5), void Function(HealthResult result)? onResult, void Function()? onUnhealthy}) : _transport = transport, _endpoint = endpoint, _onResult = onResult, _onUnhealthy = onUnhealthy;
  final HealthTransport _transport;
  final Uri _endpoint;
  final Duration interval;
  final Duration timeout;
  final void Function(HealthResult result)? _onResult;
  final void Function()? _onUnhealthy;
  Timer? _timer;
  bool _checking = false;

  Future<HealthResult> checkOnce() async {
    if (_checking) return const HealthResult(healthy: true, latency: Duration.zero);
    _checking = true;
    try {
      final result = await _transport.check(_endpoint, timeout: timeout);
      _onResult?.call(result);
      if (!result.healthy) _onUnhealthy?.call();
      return result;
    } finally {
      _checking = false;
    }
  }

  void start() {
    _timer ??= Timer.periodic(interval, (_) => unawaited(checkOnce()));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

class AutoReconnectPolicy {
  const AutoReconnectPolicy({this.maxAttempts = 5, this.initialDelay = const Duration(seconds: 2), this.maxDelay = const Duration(minutes: 1)});
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;

  Future<bool> run(Future<bool> Function(int attempt) reconnect) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (await reconnect(attempt)) return true;
      if (attempt < maxAttempts) {
        final multiplier = 1 << (attempt - 1).clamp(0, 20).toInt();
        final delay = Duration(milliseconds: (initialDelay.inMilliseconds * multiplier).clamp(0, maxDelay.inMilliseconds).toInt());
        await Future<void>.delayed(delay);
      }
    }
    return false;
  }
}
