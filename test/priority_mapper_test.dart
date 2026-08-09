import 'package:flutter_test/flutter_test.dart';
import 'package:my_torrent/src/models.dart';
import 'package:my_torrent/src/priority_mapper.dart';

void main() {
  const files = <DownloadFile>[
    DownloadFile(index: 0, name: 'release.iso', size: 1),
    DownloadFile(index: 1, name: 'release.sig', size: 1),
    DownloadFile(index: 2, name: 'readme.txt', size: 1),
  ];

  test('selects every file by default', () {
    expect(mapFilePriorities(files, <int>{0, 1, 2}), <int>[1, 1, 1]);
  });

  test('maps unchecked files to skip priority', () {
    expect(mapFilePriorities(files, <int>{0, 2}), <int>[1, 0, 1]);
  });
}
