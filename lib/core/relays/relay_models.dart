class RelayConfig {
  RelayConfig({required this.id, required this.name, required this.hostname, required this.uuid, required this.path, this.port = 443, this.active = false, DateTime? createdAt}) : createdAt = createdAt ?? DateTime.now().toUtc();

  final String id;
  final String name;
  final String hostname;
  final int port;
  final String uuid;
  final String path;
  final bool active;
  final DateTime createdAt;

  RelayConfig copyWith({String? name, bool? active}) => RelayConfig(id: id, name: name ?? this.name, hostname: hostname, port: port, uuid: uuid, path: path, active: active ?? this.active, createdAt: createdAt);

  Map<String, Object?> toMetadataJson() => <String, Object?>{'id': id, 'name': name, 'hostname': hostname, 'port': port, 'active': active, 'createdAt': createdAt.toUtc().toIso8601String()};

  static RelayConfig? fromMetadataJson(Map<String, Object?> metadata, {required String uuid, required String path}) {
    final id = metadata['id'];
    final name = metadata['name'];
    final hostname = metadata['hostname'];
    final port = metadata['port'];
    final active = metadata['active'];
    final createdAt = metadata['createdAt'];
    if (id is! String || name is! String || hostname is! String || port is! num || active is! bool || createdAt is! String) return null;
    final parsedDate = DateTime.tryParse(createdAt);
    if (parsedDate == null) return null;
    return RelayConfig(id: id, name: name, hostname: hostname, port: port.toInt(), uuid: uuid, path: path, active: active, createdAt: parsedDate);
  }
}

class CloudflareDeployRequest {
  const CloudflareDeployRequest({required this.apiToken, required this.accountId, required this.scriptName, required this.name, this.workerScript});
  final String apiToken;
  final String accountId;
  final String scriptName;
  final String name;
  final String? workerScript;
}
