import 'dart:async';
import 'dart:io';

abstract interface class CoreHandle {
  Stream<List<int>> get stdout;
  Stream<List<int>> get stderr;
  Future<int> get exitCode;
  bool kill();
}

abstract interface class CoreLauncher {
  Future<CoreHandle> launch(String executable, List<String> arguments);
}

class ProcessCoreLauncher implements CoreLauncher {
  @override
  Future<CoreHandle> launch(String executable, List<String> arguments) async {
    final process = await Process.start(executable, arguments);
    return ProcessCoreHandle(process);
  }
}

class ProcessCoreHandle implements CoreHandle {
  ProcessCoreHandle(this._process);
  final Process _process;

  @override
  Stream<List<int>> get stdout => _process.stdout;

  @override
  Stream<List<int>> get stderr => _process.stderr;

  @override
  Future<int> get exitCode => _process.exitCode;

  @override
  bool kill() => _process.kill(ProcessSignal.sigterm);
}
