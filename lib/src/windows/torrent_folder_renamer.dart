import 'dart:io';

import '../app_error.dart';

class TorrentFolderRenamer {
  const TorrentFolderRenamer._();

  static Future<void> rename({
    required String sourceDirectory,
    required String destinationDirectory,
  }) async {
    if (_samePath(sourceDirectory, destinationDirectory)) return;
    final source = Directory(sourceDirectory);
    final destination = Directory(destinationDirectory);
    if (!await source.exists() || await destination.exists()) {
      throw const AppException(AppErrorCode.downloadFolderConflict);
    }
    await source.rename(destinationDirectory);
  }

  static Future<void> removeLegacyLink(String? path) async {
    if (path == null || !Platform.isWindows) return;
    if (await FileSystemEntity.type(path, followLinks: false) ==
        FileSystemEntityType.link) {
      await Link(path).delete();
    }
  }

  static bool _samePath(String first, String second) =>
      first.replaceAll('/', '\\').toLowerCase() ==
      second.replaceAll('/', '\\').toLowerCase();
}
