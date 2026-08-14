import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_torrent/src/windows/torrent_folder_renamer.dart';

void main() {
  test('renames the completed torrent folder to the configured name', () async {
    final temporary = await Directory.systemTemp.createTemp('my_torrent_test_');
    addTearDown(() => temporary.delete(recursive: true));
    final source = Directory(
      '${temporary.path}${Platform.pathSeparator}Original torrent',
    );
    final destination =
        '${temporary.path}${Platform.pathSeparator}Custom download';
    await source.create();
    await File(
      '${source.path}${Platform.pathSeparator}payload.txt',
    ).writeAsString('payload');

    await TorrentFolderRenamer.rename(
      sourceDirectory: source.path,
      destinationDirectory: destination,
    );

    expect(await source.exists(), isFalse);
    expect(
      await File(
        '$destination${Platform.pathSeparator}payload.txt',
      ).readAsString(),
      'payload',
    );
  });
}
