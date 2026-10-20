import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import 'app_directories.dart';
import 'core_binary_resolver.dart';

class CoreBinaryInstaller {
  const CoreBinaryInstaller(this.directories);
  final AppDirectories directories;

  Future<CoreBinaryInfo?> installBundledWindowsCore() async {
    if (!Platform.isWindows) return null;
    final executable = File(directories.coreBinary);
    final hashFile = File(directories.coreHash);
    final bundledHash = await _readAssetHash();
    if (bundledHash == null) return null;
    if (await executable.exists() && await hashFile.exists()) {
      final existing = await CoreBinaryResolver(directories).resolve();
      if (existing != null &&
          existing.sha256 == bundledHash &&
          await _matchesHash(executable, bundledHash)) {
        return existing;
      }
    }

    final exeBytes = await _loadBytes('assets/core/windows-amd64/sing-box.exe');
    final dllBytes = await _loadBytes('assets/core/windows-amd64/libcronet.dll');
    await directories.core.create(recursive: true);
    await executable.writeAsBytes(exeBytes, flush: true);
    await File('${directories.core.path}${Platform.pathSeparator}libcronet.dll').writeAsBytes(dllBytes, flush: true);
    await hashFile.writeAsString('$bundledHash  sing-box.exe\n', flush: true);
    return CoreBinaryResolver(directories).resolve();
  }

  Future<bool> _matchesHash(File file, String expected) async {
    final actual = sha256.convert(await file.readAsBytes()).toString();
    return actual.toLowerCase() == expected.toLowerCase();
  }

  Future<String?> _readAssetHash() async {
    try {
      final text = await rootBundle.loadString('assets/core/windows-amd64/sing-box.exe.sha256');
      final match = RegExp(r'\b[0-9a-fA-F]{64}\b').firstMatch(text);
      return match?.group(0)?.toLowerCase();
    } on Object {
      return null;
    }
  }

  Future<List<int>> _loadBytes(String asset) async {
    final data = await rootBundle.load(asset);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}
