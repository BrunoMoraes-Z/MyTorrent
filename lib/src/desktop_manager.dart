import 'dart:io';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class DesktopManager with WindowListener, TrayListener {
  Future<void> initialize() async {
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
    trayManager.addListener(this);
    final iconPath = _trayIconPath();
    await trayManager.setIcon(iconPath);
    await trayManager.setToolTip('My Torrent');
    await trayManager.setContextMenu(
      Menu(
        items: <MenuItem>[
          MenuItem(key: 'show', label: 'Abrir My Torrent'),
          MenuItem.separator(),
          MenuItem(key: 'exit', label: 'Encerrar'),
        ],
      ),
    );
  }

  String _trayIconPath() {
    final executableDirectory = File(Platform.resolvedExecutable).parent.path;
    final bundled =
        '$executableDirectory${Platform.pathSeparator}data${Platform.pathSeparator}flutter_assets${Platform.pathSeparator}assets${Platform.pathSeparator}icons${Platform.pathSeparator}app_icon.ico';
    return File(bundled).existsSync() ? bundled : 'assets/icons/app_icon.ico';
  }

  Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  void onWindowClose() {
    windowManager.hide();
  }

  @override
  void onTrayIconMouseDown() {
    showWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show') {
      showWindow();
    }
    if (menuItem.key == 'exit') {
      trayManager.destroy();
      windowManager.destroy();
      exit(0);
    }
  }
}
