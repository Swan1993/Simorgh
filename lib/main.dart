import 'dart:io';

import 'package:flutter/material.dart';

import 'app.dart';
import 'app/composition.dart';
import 'core/desktop/desktop_shell_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServices.create();

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await DesktopShellService.instance.init(
      onExitRequested: services.dispose,
    );
  }

  runApp(SimorghApp(services: services));
}
