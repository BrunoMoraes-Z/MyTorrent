import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_torrent/src/activation_source.dart';

void main() {
  test('accepts a magnet activation regardless of scheme case', () {
    expect(
      activationSource(<String>['--protocol', 'MAGNET:?xt=urn:btih:abcdef']),
      'MAGNET:?xt=urn:btih:abcdef',
    );
  });

  test('accepts an existing torrent file activation', () async {
    final directory = await Directory.systemTemp.createTemp('my_torrent_');
    addTearDown(() => directory.delete(recursive: true));
    final torrent = File(
      '${directory.path}${Platform.pathSeparator}FILE.TORRENT',
    );
    await torrent.writeAsString('torrent');

    expect(activationSource(<String>[torrent.path]), torrent.path);
  });

  test('rejects a remote torrent URL from an external activation', () {
    expect(
      activationSource(<String>['https://example.com/release.torrent']),
      isNull,
    );
  });
}
