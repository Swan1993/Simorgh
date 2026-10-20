import 'dart:io';

import 'package:flutter/material.dart';

import 'app.dart';
import 'app/composition.dart';
import 'core/desktop/desktop_shell_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final servicesFuture = AppServices.create().then((services) async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await DesktopShellService.instance.init(
        onExitRequested: services.dispose,
      );
    }
    return services;
  });

  runApp(SimorghApp(servicesFuture: servicesFuture));
}
