import 'dart:io';

import 'app_error.dart';

class DownloadDestination {
  const DownloadDestination._();

  static String folderName(String value) {
    final name = value.trim();
    if (name.isEmpty || name == '.' || name == '..') {
      throw const AppException(AppErrorCode.folderNameRequired);
    }
    if (name.contains(RegExp(r'[<>:"/\\|?*]'))) {
      throw const AppException(AppErrorCode.folderNameInvalidCharacters);
    }
    return name;
  }

  static String suggestedFolderName(String value) {
    final sanitized = value.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    return sanitized.isEmpty || sanitized == '.' || sanitized == '..'
        ? 'download'
        : sanitized;
  }

  static String path(String parentDirectory, String folder) =>
      '${parentDirectory.trim()}${Platform.pathSeparator}${folderName(folder)}';
}
