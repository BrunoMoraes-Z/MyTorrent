import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_torrent/src/download_destination.dart';

void main() {
  test('builds a dedicated download directory', () {
    expect(
      DownloadDestination.path(r'C:\Downloads', 'Arch Linux'),
      'C:${Platform.pathSeparator}Downloads${Platform.pathSeparator}Arch Linux',
    );
  });

  test('rejects invalid download folder names', () {
    expect(
      () => DownloadDestination.folderName(r'bad/name'),
      throwsA(isA<FormatException>()),
    );
  });

  test('sanitizes a torrent name for use as the suggested folder', () {
    expect(
      DownloadDestination.suggestedFolderName('release: 2026/08'),
      'release_ 2026_08',
    );
  });
}
