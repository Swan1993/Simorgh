import 'dart:io';

import 'app_directories.dart';

class CoreBinaryInfo {
  const CoreBinaryInfo({required this.path, required this.sha256});
  final String path;
  final String? sha256;
}

class CoreBinaryResolver {
  const CoreBinaryResolver(this.directories);
  final AppDirectories directories;

  Future<CoreBinaryInfo?> resolve() async {
    final binary = File(directories.coreBinary);
    if (!await binary.exists()) return null;
    final hashFile = File(directories.coreHash);
    final hash = await hashFile.exists() ? await _readHash(hashFile) : null;
    if (hash == null) return null;
    return CoreBinaryInfo(path: binary.path, sha256: hash);
  }

  Future<String?> _readHash(File file) async {
    final text = await file.readAsString();
    final match = RegExp(r'\b[0-9a-fA-F]{64}\b').firstMatch(text);
    return match?.group(0)?.toLowerCase();
  }
}
