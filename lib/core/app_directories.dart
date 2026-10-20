import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AppDirectories {
  const AppDirectories({required this.root});
  final Directory root;

  Directory get data => Directory(_join(root.path, 'data'));
  Directory get logs => Directory(_join(data.path, 'logs'));
  Directory get cache => Directory(_join(data.path, 'cache'));
  Directory get core => Directory(_join(data.path, 'core'));
  String get relayMetadata => _join(data.path, 'relays.json');
  String get ipCache => _join(cache.path, 'clean-ips.json');
  String get logFile => _join(logs.path, 'simorgh.jsonl');
  String get coreBinary => _join(core.path, Platform.isWindows ? 'sing-box.exe' : 'sing-box');
  String get coreHash => _join(core.path, 'sing-box.sha256');

  Future<void> ensure() async {
    await data.create(recursive: true);
    await logs.create(recursive: true);
    await cache.create(recursive: true);
    await core.create(recursive: true);
  }

  static Future<AppDirectories> create() async {
    final root = await getApplicationSupportDirectory();
    final directories = AppDirectories(root: root);
    await directories.ensure();
    return directories;
  }
}

String _join(String left, String right) => '$left${Platform.pathSeparator}$right';
