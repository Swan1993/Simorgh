import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:simorgh/core/app_directories.dart';
import 'package:simorgh/core/core_binary_resolver.dart';

void main() {
  test('resolver requires a binary and a 64-character hash manifest', () async {
    final root = Directory.systemTemp.createTempSync('simorgh-binary-');
    addTearDown(() => root.deleteSync(recursive: true));
    final directories = AppDirectories(root: root);
    await directories.ensure();
    final binary = File(directories.coreBinary)..writeAsStringSync('core');
    expect(await CoreBinaryResolver(directories).resolve(), isNull);
    await File(directories.coreHash).writeAsString('0' * 64);
    final info = await CoreBinaryResolver(directories).resolve();
    expect(info?.path, binary.path);
    expect(info?.sha256, '0' * 64);
  });
}
