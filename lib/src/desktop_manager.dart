import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../l10n/generated/app_localizations.dart';
import 'models.dart';

class DesktopManager with WindowListener, TrayListener {
  AppLanguage _language = AppLanguage.en;

  Future<void> initialize() async {
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
    trayManager.addListener(this);
    final iconPath = _trayIconPath();
    await trayManager.setIcon(iconPath);
    await updateLanguage(_language);
  }

  Future<void> updateLanguage(AppLanguage language) async {
    _language = language;
    final l10n = lookupAppLocalizations(switch (language) {
      AppLanguage.ptBr => const Locale('pt', 'BR'),
      AppLanguage.en => const Locale('en'),
    });
    await trayManager.setToolTip('My Torrent');
    await trayManager.setContextMenu(
      Menu(
        items: <MenuItem>[
          MenuItem(key: 'show', label: l10n.trayOpen),
          MenuItem.separator(),
          MenuItem(key: 'exit', label: l10n.trayExit),
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

  Future<void> restart() async {
    await Process.start(
      Platform.resolvedExecutable,
      const <String>[],
      mode: ProcessStartMode.detached,
    );
    await trayManager.destroy();
    await windowManager.destroy();
    exit(0);
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
