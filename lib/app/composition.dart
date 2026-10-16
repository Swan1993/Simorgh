import 'dart:io';

import '../core/app_directories.dart';
import '../core/connection/connection_session.dart';
import '../core/core_binary_resolver.dart';
import '../core/core_binary_installer.dart';
import '../core/core_service.dart';
import '../core/logging/log_service.dart';
import '../core/logging/log_sink.dart';
import '../core/logging/redactor.dart';
import '../core/relays/relay_repository.dart';
import '../core/proxy_manager.dart';
import '../core/scanner/ip_cache.dart';
import '../core/scanner/ip_scanner.dart';
import '../core/security/secret_store.dart';

class AppServices {
  AppServices._({
    required this.directories,
    required this.logger,
    required this.secrets,
    required this.relays,
    required this.scanner,
    required this.core,
    required this.connection,
  });

  final AppDirectories directories;
  final LogService logger;
  final SecretStore secrets;
  final RelayRepository relays;
  final IpScannerService scanner;
  final CoreService core;
  final ConnectionSession connection;

  static Future<AppServices> create() async {
    final directories = await AppDirectories.create();
    await CoreBinaryInstaller(directories).installBundledWindowsCore();
    final secrets = SecureSecretStore();
    final redactor = RedactorWithSecrets(secrets);
    await redactor.refresh();
    final logger = LogService(
      redactor: redactor,
      sink: RotatingFileLogSink(path: directories.logFile),
    );
    final relays = RelayRepository(
      metadataPath: directories.relayMetadata,
      secrets: secrets,
    );
    final scanner = IpScannerService(
      cache: IpCandidateCache(path: directories.ipCache),
    );
    final proxy = WindowsSystemProxyManager(
      snapshotPath: '${directories.data.path}${Platform.pathSeparator}proxy-snapshot.json',
    );
    await proxy.recover();
    await proxy.restore();
    final core = CoreService(logger: logger, proxyManager: proxy);
    final connection = ProductionConnectionSession(
      relays: relays,
      binaries: CoreBinaryResolver(directories),
      scanner: scanner,
      core: core,
      logger: logger,
    );
    return AppServices._(
      directories: directories,
      logger: logger,
      secrets: secrets,
      relays: relays,
      scanner: scanner,
      core: core,
      connection: connection,
    );
  }

  Future<void> dispose() async {
    try {
      await connection.dispose();
    } finally {
      await logger.dispose();
    }
  }
}

/// Bridges secure values into the redactor without exposing values to logs.
/// The registry is populated only when a service explicitly provides a value.
class RedactorWithSecrets extends Redactor {
  RedactorWithSecrets(SecretStore secrets) : _secrets = secrets;
  final SecretStore _secrets;

  Future<void> refresh() async {
    for (final key in <String>[
      SecretKeys.cloudflareApiToken,
      SecretKeys.cloudflareAccountId,
      SecretKeys.aiApiKey,
    ]) {
      final value = await _secrets.read(key);
      if (value != null) registerSecret(value);
    }
  }
}
