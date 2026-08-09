import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app.dart';
import 'src/app_controller.dart';
import 'src/desktop_manager.dart';

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
  final controller = await AppController.create();
  runApp(
    TorrentDeskApp(
      controller: controller,
      initialSource: Platform.executableArguments.cast<String?>().firstWhere(
        (argument) =>
            argument != null &&
            (argument.startsWith('magnet:') || argument.endsWith('.torrent')),
        orElse: () => null,
      ),
    ),
  );
}
