import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class DesktopShellService with TrayListener, WindowListener {
  DesktopShellService({this.minimizeToTray = true});
  final bool minimizeToTray;
  bool _initialized = false;

  Future<void> initialize({String? iconPath}) async {
    if (!Platform.isWindows || _initialized) return;
    _initialized = true;
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    trayManager.addListener(this);
    if (iconPath != null && iconPath.isNotEmpty) {
      await trayManager.setIcon(iconPath);
    }
    await trayManager.setToolTip('Simorgh');
    await trayManager.setContextMenu(Menu(items: <MenuItem>[
      MenuItem(key: 'show', label: 'Show Simorgh'),
      MenuItem.separator(),
      MenuItem(key: 'exit', label: 'Exit'),
    ]));
    await windowManager.setPreventClose(minimizeToTray);
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    await windowManager.setPreventClose(false);
    _initialized = false;
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show') {
      windowManager.show();
      windowManager.focus();
    } else if (menuItem.key == 'exit') {
      windowManager.destroy();
    }
  }

  @override
  void onWindowClose() {
    if (minimizeToTray) {
      windowManager.hide();
    } else {
      windowManager.destroy();
    }
  }
}
