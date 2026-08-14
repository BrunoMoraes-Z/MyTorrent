import 'dart:io';

import 'app_error.dart';

class DownloadDestination {
  const DownloadDestination._();

  static String basePath(String value) {
    final path = value.trim();
    if (path.isEmpty) {
      throw const AppException(AppErrorCode.destinationNotFound);
    }
    return path;
  }

  static String savePath(String baseDirectory, String folderName) {
    final directory = basePath(baseDirectory);
    final folder = folderName.trim();
    if (!_isValidFolderName(folder)) {
      throw const AppException(AppErrorCode.downloadFolderInvalid);
    }
    final separator = directory.endsWith(Platform.pathSeparator)
        ? ''
        : Platform.pathSeparator;
    return '$directory$separator$folder';
  }

  static String suggestedFolderName(String value) {
    final sanitized = value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceFirst(RegExp(r'[. ]+$'), '');
    return _isValidFolderName(sanitized) ? sanitized : 'download';
  }

  static bool _isValidFolderName(String value) {
    if (value.isEmpty || value == '.' || value == '..') return false;
    if (value.endsWith('.') || value.endsWith(' ')) return false;
    if (value.contains(RegExp(r'[\\/:*?"<>|]'))) return false;
    final stem = value.split('.').first.toUpperCase();
    return !const <String>{
      'CON',
      'PRN',
      'AUX',
      'NUL',
      'COM1',
      'COM2',
      'COM3',
      'COM4',
      'COM5',
      'COM6',
      'COM7',
      'COM8',
      'COM9',
      'LPT1',
      'LPT2',
      'LPT3',
      'LPT4',
      'LPT5',
      'LPT6',
      'LPT7',
      'LPT8',
      'LPT9',
    }.contains(stem);
  }
}
