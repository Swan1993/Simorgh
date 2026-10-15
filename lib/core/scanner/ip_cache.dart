import 'dart:convert';
import 'dart:io';

class CachedIp {
  const CachedIp({required this.ip, required this.latencyMs, required this.savedAt});
  final String ip;
  final int latencyMs;
  final DateTime savedAt;

  Map<String, Object?> toJson() => <String, Object?>{'ip': ip, 'latencyMs': latencyMs, 'savedAt': savedAt.toUtc().toIso8601String()};

  static CachedIp? fromJson(Object? value) {
    if (value is! Map) return null;
    final ip = value['ip'];
    final latency = value['latencyMs'];
    final savedAt = value['savedAt'];
    if (ip is! String || latency is! num || savedAt is! String) return null;
    final parsed = DateTime.tryParse(savedAt);
    if (parsed == null) return null;
    return CachedIp(ip: ip, latencyMs: latency.toInt(), savedAt: parsed);
  }
}

class IpCandidateCache {
  IpCandidateCache({required String path, this.maxAge = const Duration(hours: 12)}) : _file = File(path);
  final File _file;
  final Duration maxAge;

  Future<List<CachedIp>> read({DateTime Function()? now}) async {
    if (!await _file.exists()) return const <CachedIp>[];
    try {
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is! List) return const <CachedIp>[];
      final current = (now ?? DateTime.now)();
      return List<CachedIp>.unmodifiable(decoded.map(CachedIp.fromJson).whereType<CachedIp>().where((item) => current.difference(item.savedAt) <= maxAge));
    } on Object {
      return const <CachedIp>[];
    }
  }

  Future<void> write(Iterable<CachedIp> values) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(jsonEncode(values.map((item) => item.toJson()).toList()), flush: true);
  }

  Future<void> clear() async {
    if (await _file.exists()) await _file.delete();
  }
}
