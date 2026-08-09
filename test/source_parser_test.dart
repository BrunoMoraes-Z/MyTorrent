import 'package:flutter_test/flutter_test.dart';
import 'package:my_torrent/src/models.dart';
import 'package:my_torrent/src/source_parser.dart';

void main() {
  const parser = TorrentSourceParser();

  test('recognizes a magnet URI', () {
    final source = parser.parse('magnet:?xt=urn:btih:abcdef');
    expect(source.type, TorrentSourceType.magnet);
  });

  test('recognizes an HTTP torrent URL', () {
    final source = parser.parse('https://example.com/release.torrent');
    expect(source.type, TorrentSourceType.url);
  });

  test('rejects unsupported input before polling', () {
    expect(
      () => parser.parse('not-a-torrent'),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects an HTTP URL that is not a torrent file', () {
    expect(
      () => parser.parse('https://example.com/download'),
      throwsA(isA<FormatException>()),
    );
  });
}
