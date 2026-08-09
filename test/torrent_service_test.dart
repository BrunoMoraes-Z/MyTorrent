import 'package:flutter_test/flutter_test.dart';
import 'package:libtorrent_flutter/libtorrent_flutter.dart';
import 'package:my_torrent/src/torrent_service.dart';

void main() {
  test('disables DHT and port mapping when requested', () {
    final configuration = TorrentService.sessionConfiguration(
      const BtConfig(disableDht: false, disableUpnp: false),
      false,
    );

    expect(configuration.disableDht, isTrue);
    expect(configuration.disableUpnp, isTrue);
  });

  test('enables DHT without enabling port mapping', () {
    final configuration = TorrentService.sessionConfiguration(
      const BtConfig(disableDht: true, disableUpnp: false),
      true,
    );

    expect(configuration.disableDht, isFalse);
    expect(configuration.disableUpnp, isTrue);
  });
}
