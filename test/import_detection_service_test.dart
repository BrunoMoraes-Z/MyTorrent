import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_torrent/src/import_detection_service.dart';

void main() {
  test('emits only torrent files created after its initial snapshot', () async {
    final directory = await Directory.systemTemp.createTemp('my_torrent_scan_');
    addTearDown(() => directory.delete(recursive: true));
    await File(
      '${directory.path}${Platform.pathSeparator}old.torrent',
    ).writeAsString('old');
    final service = ImportDetectionService(
      directory,
      clipboardReader: () async => null,
    );
    final candidates = <ImportCandidate>[];
    final subscription = service.candidates.listen(candidates.add);
    addTearDown(subscription.cancel);
    addTearDown(service.dispose);

    await service.snapshotExistingTorrentFiles();
    await File(
      '${directory.path}${Platform.pathSeparator}new.torrent',
    ).writeAsString('new');
    await service.scanTorrentFiles();
    await Future<void>.delayed(Duration.zero);

    expect(candidates, hasLength(1));
    expect(candidates.single.type, ImportCandidateType.torrentFile);
    expect(candidates.single.label, 'new.torrent');
  });

  test('emits a magnet from clipboard once', () async {
    const magnet = 'magnet:?xt=urn:btih:abcdef';
    final directory = await Directory.systemTemp.createTemp(
      'my_torrent_clipboard_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final service = ImportDetectionService(
      directory,
      clipboardReader: () async => magnet,
    );
    final candidates = <ImportCandidate>[];
    final subscription = service.candidates.listen(candidates.add);
    addTearDown(subscription.cancel);
    addTearDown(service.dispose);

    await service.checkClipboard();
    await service.checkClipboard();
    await Future<void>.delayed(Duration.zero);

    expect(candidates, hasLength(1));
    expect(candidates.single.source, magnet);
  });
}
