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
    if (!await source.exists() ||
        !await canUseDestination(destinationDirectory)) {
      throw const AppException(AppErrorCode.downloadFolderConflict);
    }
    if (await destination.exists()) await destination.delete();
    await source.rename(destinationDirectory);
  }

  static Future<bool> canUseDestination(String directory) async {
    final type = await FileSystemEntity.type(directory, followLinks: false);
    if (type == FileSystemEntityType.notFound) return true;
    if (type != FileSystemEntityType.directory) return false;
    return await Directory(directory).list(followLinks: false).isEmpty;
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
