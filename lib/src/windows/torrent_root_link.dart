import 'dart:io';

import '../app_error.dart';
import '../download_destination.dart';

class TorrentRootLink {
  const TorrentRootLink._();

  static Future<String?> ensure({
    required String baseDirectory,
    required String torrentRoot,
    required String destinationDirectory,
  }) async {
    if (!Platform.isWindows) return null;
    final rootPath = DownloadDestination.savePath(baseDirectory, torrentRoot);
    if (_samePath(rootPath, destinationDirectory)) return null;

    await Directory(destinationDirectory).create(recursive: true);
    final type = await FileSystemEntity.type(rootPath, followLinks: false);
    if (type != FileSystemEntityType.notFound) {
      if (type == FileSystemEntityType.link &&
          _samePath(await Link(rootPath).target(), destinationDirectory)) {
        return rootPath;
      }
      throw const AppException(AppErrorCode.downloadFolderConflict);
    }

    final result = await Process.run('powershell.exe', <String>[
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      'New-Item -ItemType Junction -Path ${_powerShellLiteral(rootPath)} '
          '-Target ${_powerShellLiteral(destinationDirectory)} | Out-Null',
    ]);
    if (result.exitCode != 0) {
      throw const AppException(AppErrorCode.downloadFolderConflict);
    }
    return rootPath;
  }

  static Future<void> remove(String? path) async {
    if (path == null || !Platform.isWindows) return;
    if (await FileSystemEntity.type(path, followLinks: false) ==
        FileSystemEntityType.link) {
      await Link(path).delete();
    }
  }

  static bool _samePath(String first, String second) =>
      first.replaceAll('/', '\\').toLowerCase() ==
      second.replaceAll('/', '\\').toLowerCase();

  static String _powerShellLiteral(String value) =>
      "'${value.replaceAll("'", "''")}'";
}
