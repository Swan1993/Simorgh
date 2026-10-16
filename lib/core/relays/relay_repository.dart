import 'dart:convert';
import 'dart:io';

import '../security/secret_store.dart';
import 'relay_models.dart';

class RelayRepository {
  RelayRepository({required String metadataPath, required SecretStore secrets}) : _file = File(metadataPath), _secrets = secrets;
  final File _file;
  final SecretStore _secrets;

  Future<List<RelayConfig>> list() async {
    final metadata = await _readMetadata();
    final relays = <RelayConfig>[];
    for (final item in metadata) {
      final id = item['id'];
      final secretKey = item['secretKey'];
      if (id is! String || secretKey is! String) {
        continue;
      }
      final secret = await _secrets.read(secretKey);
      if (secret == null) {
        continue;
      }
      try {
        final decoded = jsonDecode(secret);
        if (decoded is Map) {
          final relay = RelayConfig.fromMetadataJson(
            Map<String, Object?>.from(item),
            uuid: decoded['uuid'] as String,
            path: decoded['path'] as String,
          );
          if (relay != null) {
            relays.add(relay);
          }
        }
      } on Object {
        // Ignore one corrupt entry without hiding the remaining relays.
      }
    }
    return List<RelayConfig>.unmodifiable(relays);
  }

  Future<RelayConfig?> active() async {
    final relays = await list();
    for (final relay in relays) {
      if (relay.active) {
        return relay;
      }
    }
    return relays.length == 1 ? relays.single : null;
  }

  Future<void> save(RelayConfig relay) async {
    final metadata = await _readMetadata();
    final secretKey = _secretKey(relay.id);
    await _secrets.write(secretKey, jsonEncode(<String, String>{'uuid': relay.uuid, 'path': relay.path}));
    final item = <String, Object?>{...relay.toMetadataJson(), 'secretKey': secretKey};
    final index = metadata.indexWhere((value) => value['id'] == relay.id);
    if (index == -1) {
      metadata.add(item);
    } else {
      metadata[index] = item;
    }
    await _writeMetadata(metadata);
  }

  Future<void> delete(String id) async {
    final metadata = await _readMetadata();
    final removed = metadata.where((value) => value['id'] == id).toList(growable: false);
    for (final item in removed) {
      final key = item['secretKey'];
      if (key is String) {
        await _secrets.delete(key);
      }
    }
    metadata.removeWhere((value) => value['id'] == id);
    await _writeMetadata(metadata);
  }

  Future<void> setActive(String id) async {
    final metadata = await _readMetadata();
    for (final item in metadata) {
      item['active'] = item['id'] == id;
    }
    await _writeMetadata(metadata);
  }

  Future<void> clear() async {
    final metadata = await _readMetadata();
    for (final item in metadata) {
      final key = item['secretKey'];
      if (key is String) {
        await _secrets.delete(key);
      }
    }
    if (await _file.exists()) {
      await _file.delete();
    }
  }

  String _secretKey(String id) => 'relay_$id';

  Future<List<Map<String, Object?>>> _readMetadata() async {
    if (!await _file.exists()) {
      return <Map<String, Object?>>[];
    }
    try {
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is! List) {
        return <Map<String, Object?>>[];
      }
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, Object?>.from(item))
          .toList();
    } on Object {
      return <Map<String, Object?>>[];
    }
  }

  Future<void> _writeMetadata(List<Map<String, Object?>> metadata) async {
    await _file.parent.create(recursive: true);
    final temporary = File('${_file.path}.tmp');
    await temporary.writeAsString(jsonEncode(metadata), flush: true);
    if (await _file.exists()) {
      await _file.delete();
    }
    await temporary.rename(_file.path);
  }
}
