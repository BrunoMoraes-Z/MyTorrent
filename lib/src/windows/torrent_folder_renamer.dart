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
    if (!await destination.exists()) {
      await source.rename(destinationDirectory);
      return;
    }
    await _merge(source, destination);
  }

  static Future<bool> canUseDestination(String directory) async {
    final type = await FileSystemEntity.type(directory, followLinks: false);
    if (type == FileSystemEntityType.notFound) return true;
    return type == FileSystemEntityType.directory;
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

  static Future<void> _merge(Directory source, Directory destination) async {
    await for (final entity in source.list(followLinks: false)) {
      final targetPath =
          '${destination.path}${Platform.pathSeparator}'
          '${_name(entity.path)}';
      final targetType = await FileSystemEntity.type(
        targetPath,
        followLinks: false,
      );
      if (entity is Directory) {
        if (targetType == FileSystemEntityType.notFound) {
          await entity.rename(targetPath);
        } else if (targetType == FileSystemEntityType.directory) {
          await _merge(entity, Directory(targetPath));
        } else {
          throw const AppException(AppErrorCode.downloadFolderConflict);
        }
      } else if (entity is File) {
        if (targetType == FileSystemEntityType.notFound) {
          await entity.rename(targetPath);
        } else if (targetType == FileSystemEntityType.file &&
            await _sameFileContents(entity, File(targetPath))) {
          await entity.delete();
        } else {
          throw const AppException(AppErrorCode.downloadFolderConflict);
        }
      } else {
        throw const AppException(AppErrorCode.downloadFolderConflict);
      }
    }
    await source.delete();
  }

  static String _name(String path) {
    final separator = RegExp(r'[\\/]');
    return path.split(separator).last;
  }

  static Future<bool> _sameFileContents(File first, File second) async {
    if (await first.length() != await second.length()) return false;
    final firstHandle = await first.open();
    final secondHandle = await second.open();
    try {
      while (true) {
        final firstBytes = await firstHandle.read(64 * 1024);
        final secondBytes = await secondHandle.read(64 * 1024);
        if (firstBytes.length != secondBytes.length) return false;
        for (var index = 0; index < firstBytes.length; index++) {
          if (firstBytes[index] != secondBytes[index]) return false;
        }
        if (firstBytes.isEmpty) return true;
      }
    } finally {
      await firstHandle.close();
      await secondHandle.close();
    }
  }
}
