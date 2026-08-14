import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app.dart';
import 'src/activation_source.dart';
import 'src/app_controller.dart';
import 'src/desktop_manager.dart';
import 'src/import_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  final desktopManager = DesktopManager();
  final options = WindowOptions(
    size: const Size(1280, 780),
    minimumSize: const Size(980, 640),
    center: true,
    title: 'My Torrent',
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  await desktopManager.initialize();
  try {
    await protocolHandler.register('magnet');
  } catch (_) {
    // MSIX registers the protocol; the development runner may not be eligible.
  }
  final notificationService = ImportNotificationService();
  await notificationService.initialize();
  final protocolInitialUrl = await protocolHandler.getInitialUrl();
  final initialSource = activationSource(<String>[
    ...Platform.executableArguments,
    protocolInitialUrl ?? '',
  ]);
  final controller = await AppController.create(
    restartApplication: desktopManager.restart,
    updateDesktopLanguage: desktopManager.updateLanguage,
  );
  await desktopManager.updateLanguage(controller.settings.language);
  runApp(
    MyTorrent(
      controller: controller,
      desktopManager: desktopManager,
      notificationService: notificationService,
      initialSource: initialSource,
    ),
  );
}
