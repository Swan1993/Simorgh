import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Manages the system tray icon and window show/hide behaviour
/// for desktop platforms (Windows / macOS / Linux).
class DesktopShellService with WindowListener {
  DesktopShellService._();
  static final DesktopShellService instance = DesktopShellService._();

  // IMPORTANT: keep strong references. If these are garbage-collected,
  // the native handle is released and the tray icon disappears.
  TrayIcon? _trayIcon;
  Menu? menu;
  MenuItem? showItem;
  MenuItem? hideItem;
  MenuItem? exitItem;

  bool _initialized = false;
  Future<void> Function()? _onExitRequested;

  static bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  Future<void> init({Future<void> Function()? onExitRequested}) async {
    if (_initialized || !_isDesktop) return;
    _onExitRequested = onExitRequested;

    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    // Intercept the close button so the app hides to tray instead of quitting.
    await windowManager.setPreventClose(true);

    if (!_setupTray()) {
      windowManager.removeListener(this);
      await windowManager.setPreventClose(false);
      _onExitRequested = null;
      return;
    }
    _initialized = true;
  }

  bool _setupTray() {
    final trayIcon = TrayIcon.create();
    if (trayIcon == null) {
      debugPrint('DesktopShellService: failed to create tray icon');
      return false;
    }

    try {
      trayIcon.icon = ImageAsset.fromAsset(
        Platform.isWindows
            ? 'assets/logo/logo-icon.ico'
            : 'assets/logo/logo.png',
      );
    } catch (e) {
      // setIcon-style failures now throw ArgumentError on every platform.
      debugPrint('DesktopShellService: could not load tray icon: $e');
    }

    trayIcon.setTooltip('Simorgh');

    // ---- Menu ----
    final menu = Menu.create()!;

    final showItem = MenuItem.createWithLabelAndType(
      'Show Window',
      MenuItemType.normal,
    )!;
    showItem.addListener((event) {
      if (event is MenuItemClickedEvent) showWindow();
    });

    final hideItem = MenuItem.createWithLabelAndType(
      'Hide Window',
      MenuItemType.normal,
    )!;
    hideItem.addListener((event) {
      if (event is MenuItemClickedEvent) hideWindow();
    });

    final exitItem = MenuItem.createWithLabelAndType(
      'Exit',
      MenuItemType.normal,
    )!;
    exitItem.addListener((event) {
      if (event is MenuItemClickedEvent) exitApp();
    });

    menu.addItem(showItem);
    menu.addItem(hideItem);
    menu.addSeparator();
    menu.addItem(exitItem);

    trayIcon.setContextMenu(menu);
    // Replaces the old popUpContextMenu() call in onTrayIconRightMouseDown.
    trayIcon.setContextMenuTrigger(ContextMenuTrigger.rightClicked);

    // Left click / double click (not reported on Linux: the panel handles it).
    trayIcon.addListener((event) {
      switch (event) {
        case TrayIconClickedEvent():
        case TrayIconDoubleClickedEvent():
          showWindow();
        default:
          break;
      }
    });

    trayIcon.setVisible(true);

    _trayIcon = trayIcon;
    this.menu = menu;
    this.showItem = showItem;
    this.hideItem = hideItem;
    this.exitItem = exitItem;
    return true;
  }

  // ---- Window actions ----

  Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> hideWindow() async {
    await windowManager.hide();
  }

  Future<void> exitApp() async {
    await windowManager.setPreventClose(false);
    await _onExitRequested?.call();
    dispose();
    await windowManager.destroy();
  }

  // ---- WindowListener ----

  @override
  void onWindowClose() async {
    final preventClose = await windowManager.isPreventClose();
    if (preventClose) {
      await hideWindow();
    }
  }

  // ---- Cleanup ----

  void dispose() {
    if (!_initialized) return;
    windowManager.removeListener(this);
    _trayIcon?.dispose();
    _trayIcon = null;
    menu = null;
    showItem = null;
    hideItem = null;
    exitItem = null;
    _onExitRequested = null;
    _initialized = false;
  }
}
