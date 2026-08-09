import 'dart:convert';
import 'dart:io';

import 'models.dart';

class SettingsStore {
  SettingsStore(this._directory);

  final Directory _directory;

  File get _file =>
      File('${_directory.path}${Platform.pathSeparator}settings.json');

  Future<AppSettings> load(String fallbackPath) async {
    try {
      final content = await _file.readAsString();
      final data = jsonDecode(content) as Map<String, Object?>;
      return AppSettings.fromJson(data, fallbackPath);
    } on FileSystemException {
      return AppSettings(downloadDirectory: fallbackPath);
    } on FormatException {
      return AppSettings(downloadDirectory: fallbackPath);
    }
  }

  Future<void> save(AppSettings settings) async {
    await _directory.create(recursive: true);
    final temporary = File('${_file.path}.tmp');
    await temporary.writeAsString(jsonEncode(settings.toJson()), flush: true);
    await temporary.rename(_file.path);
  }
}
