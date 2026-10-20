import 'dart:io';
import 'dart:convert';

abstract interface class SystemProxyManager {
  Future<void> enable({required String host, required int port});
  Future<void> restore();
}

class NoopProxyManager implements SystemProxyManager {
  @override
  Future<void> enable({required String host, required int port}) async {}

  @override
  Future<void> restore() async {}
}

/// Windows user-level proxy manager backed by the documented Internet Settings
/// registry values. A snapshot is kept in memory and restored on stop.
class WindowsSystemProxyManager implements SystemProxyManager {
  WindowsSystemProxyManager({this.snapshotPath});
  static const _key =
      r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings';
  final String? snapshotPath;
  Map<String, String?>? _snapshot;

  Future<void> recover() async {
    final path = snapshotPath;
    if (path == null || !Platform.isWindows) return;
    final file = File(path);
    if (!await file.exists()) return;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map) {
        _snapshot = <String, String?>{
          for (final entry in decoded.entries)
            entry.key.toString(): entry.value?.toString(),
        };
      }
    } on Object {
      _snapshot = null;
    }
  }

  @override
  Future<void> enable({required String host, required int port}) async {
    if (!Platform.isWindows) {
      throw UnsupportedError(
        'System proxy integration is currently Windows-only.',
      );
    }
    _snapshot ??= <String, String?>{
      'ProxyEnable': await _query('ProxyEnable'),
      'ProxyServer': await _query('ProxyServer'),
      'ProxyOverride': await _query('ProxyOverride'),
    };
    await _persistSnapshot();
    try {
      await _add('ProxyEnable', 'REG_DWORD', '1');
      await _add('ProxyServer', 'REG_SZ', '$host:$port');
      await _add('ProxyOverride', 'REG_SZ', '<local>');
    } catch (_) {
      await restore();
      rethrow;
    }
  }

  @override
  Future<void> restore() async {
    final snapshot = _snapshot;
    if (snapshot == null || !Platform.isWindows) {
      return;
    }
    try {
      await _restoreValue('ProxyEnable', 'REG_DWORD', snapshot['ProxyEnable']);
      await _restoreValue('ProxyServer', 'REG_SZ', snapshot['ProxyServer']);
      await _restoreValue('ProxyOverride', 'REG_SZ', snapshot['ProxyOverride']);
    } finally {
      _snapshot = null;
      final path = snapshotPath;
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    }
  }

  Future<String?> _query(String name) async {
    final result = await Process.run('reg.exe', ['query', _key, '/v', name]);
    if (result.exitCode != 0) {
      return null;
    }
    final lines = result.stdout.toString().split(RegExp(r'\r?\n'));
    for (final line in lines) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 3 && parts.first == name) {
        return parts.sublist(2).join(' ');
      }
    }
    return null;
  }

  Future<void> _add(String name, String type, String value) async {
    final arguments = ['add', _key, '/v', name, '/t', type, '/d', value, '/f'];
    final result = await Process.run('reg.exe', arguments);
    if (result.exitCode != 0) {
      throw ProcessException(
        'reg.exe',
        arguments,
        result.stderr.toString(),
        result.exitCode,
      );
    }
  }

  Future<void> _restoreValue(String name, String type, String? value) async {
    if (value == null) {
      await Process.run('reg.exe', ['delete', _key, '/v', name, '/f']);
      return;
    }
    await _add(name, type, value);
  }

  Future<void> _persistSnapshot() async {
    final path = snapshotPath;
    if (path == null || _snapshot == null) return;
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(_snapshot), flush: true);
  }
}
