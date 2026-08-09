import 'dart:io';

class DownloadDestination {
  const DownloadDestination._();

  static String folderName(String value) {
    final name = value.trim();
    if (name.isEmpty || name == '.' || name == '..') {
      throw const FormatException('Informe um nome de pasta válido.');
    }
    if (name.contains(RegExp(r'[<>:"/\\|?*]'))) {
      throw const FormatException(
        'O nome da pasta contém caracteres inválidos.',
      );
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
