import 'package:flutter_test/flutter_test.dart';
import 'package:my_torrent/src/torrent_file_name.dart';

void main() {
  test('removes torrent folder segments from a Windows path', () {
    expect(torrentFileName(r'Release\Season 1\episode.mkv'), 'episode.mkv');
  });

  test('removes torrent folder segments from a portable path', () {
    expect(torrentFileName('Release/Season 1/episode.mkv'), 'episode.mkv');
  });
}
