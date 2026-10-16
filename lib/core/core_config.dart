import 'dart:convert';

class CoreEndpoint {
  const CoreEndpoint({
    required this.server,
    required this.port,
    required this.uuid,
    this.path = '/',
    this.serverName,
  });

  final String server;
  final int port;
  final String uuid;
  final String path;
  final String? serverName;
}

class CoreLaunchConfig {
  const CoreLaunchConfig({
    required this.binaryPath,
    required this.endpoint,
    this.expectedSha256,
    this.localSocksPort = 10808,
    this.localHttpPort = 10809,
    this.useSystemProxy = false,
    this.verifyLocalPort = false,
  });

  final String binaryPath;
  final CoreEndpoint endpoint;
  final String? expectedSha256;
  final int localSocksPort;
  final int localHttpPort;
  final bool useSystemProxy;
  final bool verifyLocalPort;
}

class CoreConfigBuilder {
  Map<String, Object?> build(CoreLaunchConfig launch) {
    _validatePort(launch.localSocksPort, 'localSocksPort');
    _validatePort(launch.localHttpPort, 'localHttpPort');
    _validatePort(launch.endpoint.port, 'endpoint.port');
    if (launch.endpoint.server.trim().isEmpty) {
      throw ArgumentError.value(launch.endpoint.server, 'endpoint.server');
    }
    if (launch.endpoint.uuid.trim().isEmpty) {
      throw ArgumentError.value(launch.endpoint.uuid, 'endpoint.uuid');
    }

    final serverName = launch.endpoint.serverName ?? launch.endpoint.server;
    return <String, Object?>{
      'log': <String, Object?>{'level': 'warn', 'timestamp': true},
      'inbounds': <Object?>[
        <String, Object?>{
          'type': 'mixed',
          'tag': 'mixed-in',
          'listen': '127.0.0.1',
          'listen_port': launch.localSocksPort,
        },
        if (launch.localHttpPort != launch.localSocksPort)
          <String, Object?>{
            'type': 'mixed',
            'tag': 'http-in',
            'listen': '127.0.0.1',
            'listen_port': launch.localHttpPort,
          },
      ],
      'outbounds': <Object?>[
        <String, Object?>{
          'type': 'vless',
          'tag': 'proxy-out',
          'server': launch.endpoint.server,
          'server_port': launch.endpoint.port,
          'uuid': launch.endpoint.uuid,
          'tls': <String, Object?>{
            'enabled': true,
            'server_name': serverName,
          },
          'transport': <String, Object?>{
            'type': 'ws',
            'path': launch.endpoint.path,
            'headers': <String, String>{'Host': serverName},
          },
        },
        <String, Object?>{'type': 'direct', 'tag': 'direct'},
        <String, Object?>{'type': 'block', 'tag': 'block'},
      ],
      'route': <String, Object?>{'final': 'proxy-out'},
    };
  }

  String encode(CoreLaunchConfig launch) => jsonEncode(build(launch));

  void _validatePort(int port, String name) {
    if (port < 1 || port > 65535) {
      throw ArgumentError.value(port, name, 'Port must be between 1 and 65535.');
    }
  }
}
