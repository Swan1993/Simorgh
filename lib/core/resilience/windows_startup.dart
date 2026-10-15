import 'dart:io';

class WindowsStartupService {
  static const _key = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
  static const _valueName = 'Simorgh';

  Future<void> setEnabled({required bool enabled, required String executablePath}) async {
    if (!Platform.isWindows) throw UnsupportedError('Windows startup is available only on Windows.');
    final result = enabled
        ? await Process.run('reg.exe', ['add', _key, '/v', _valueName, '/t', 'REG_SZ', '/d', executablePath, '/f'])
        : await Process.run('reg.exe', ['delete', _key, '/v', _valueName, '/f']);
    if (result.exitCode != 0 && enabled) throw ProcessException('reg.exe', result.arguments, result.stderr.toString(), result.exitCode);
  }
}
