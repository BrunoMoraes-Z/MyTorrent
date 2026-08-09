import 'dart:io';

import 'models.dart';

class TorrentSourceParser {
  const TorrentSourceParser();

  TorrentSource parse(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      throw const FormatException(
        'Informe um link magnet, URL ou arquivo .torrent.',
      );
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
    throw const FormatException(
      'Use um magnet, uma URL HTTP(S) ou um arquivo .torrent existente.',
    );
  }
}
