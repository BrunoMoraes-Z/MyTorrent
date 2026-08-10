import 'dart:io';

import 'models.dart';
import 'app_error.dart';

class TorrentSourceParser {
  const TorrentSourceParser();

  TorrentSource parse(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      throw const AppException(AppErrorCode.sourceRequired);
    }

    final uri = Uri.tryParse(value);
    if (uri?.scheme.toLowerCase() == 'magnet') {
      return TorrentSource(value: value, type: TorrentSourceType.magnet);
    }
    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.path.toLowerCase().endsWith('.torrent')) {
      return TorrentSource(value: value, type: TorrentSourceType.url);
    }
    if (value.toLowerCase().endsWith('.torrent') && File(value).existsSync()) {
      return TorrentSource(value: value, type: TorrentSourceType.file);
    }
    throw const AppException(AppErrorCode.sourceInvalid);
  }
}
