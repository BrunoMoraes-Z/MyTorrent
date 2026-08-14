import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_torrent/src/windows/torrent_root_link.dart';

void main() {
  test(
    'maps a torrent root to the configured download folder',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'my_torrent_test_',
      );
      addTearDown(() => temporary.delete(recursive: true));
      final base = Directory('${temporary.path}${Platform.pathSeparator}base');
      final destination =
          '${base.path}${Platform.pathSeparator}Custom download';
      await base.create();

      final link = await TorrentRootLink.ensure(
        baseDirectory: base.path,
        torrentRoot: 'Original torrent',
        destinationDirectory: destination,
      );
      final payload = File('$link${Platform.pathSeparator}payload.txt');
      await payload.writeAsString('payload');

      expect(
        await File(
          '$destination${Platform.pathSeparator}payload.txt',
        ).readAsString(),
        'payload',
      );

      await TorrentRootLink.remove(link);
      expect(
        await FileSystemEntity.type(link!, followLinks: false),
        FileSystemEntityType.notFound,
      );
    },
    skip: !Platform.isWindows,
  );
}
