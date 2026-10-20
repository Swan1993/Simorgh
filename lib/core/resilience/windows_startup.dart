import 'dart:io';

class WindowsStartupService {
  static const _key = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
  static const _valueName = 'Simorgh';

  Future<void> setEnabled({
    required bool enabled,
    required String executablePath,
  }) async {
    if (!Platform.isWindows) {
      throw UnsupportedError('Windows startup is available only on Windows.');
    }
    final command = executablePath.contains(' ')
        ? '"${executablePath.replaceAll('"', '\\"')}"'
        : executablePath;
    final arguments = enabled
      ? [
            'add',
            _key,
            '/v',
            _valueName,
            '/t',
            'REG_SZ',
            '/d',
            command,
            '/f',
          ]
        : [
            'delete',
            _key,
            '/v',
            _valueName,
            '/f',
              ];
            final result = await Process.run('reg.exe', arguments);
    if (result.exitCode != 0 && enabled) {
      throw ProcessException(
        'reg.exe',
        arguments,
        result.stderr.toString(),
        result.exitCode,
      );
    }
  }
}
