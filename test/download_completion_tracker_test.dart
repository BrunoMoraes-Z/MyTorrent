import 'package:flutter_test/flutter_test.dart';
import 'package:libtorrent_flutter/libtorrent_flutter.dart';
import 'package:my_torrent/src/download_completion_tracker.dart';

TorrentInfo _torrent({required int id, required bool isFinished}) =>
    TorrentInfo(
      id: id,
      name: 'Example $id',
      savePath: r'C:\Downloads',
      errorMsg: '',
      state: isFinished ? TorrentState.finished : TorrentState.downloading,
      progress: isFinished ? 1 : .5,
      downloadRate: 0,
      uploadRate: 0,
      totalDone: 0,
      totalWanted: 0,
      totalUploaded: 0,
      numPeers: 0,
      numSeeds: 0,
      isPaused: false,
      isFinished: isFinished,
      hasMetadata: true,
      queuePosition: 0,
    );

void main() {
  test('emits a download only when it transitions to finished', () {
    final tracker = DownloadCompletionTracker();

    expect(
      tracker.observe(<int, TorrentInfo>{
        1: _torrent(id: 1, isFinished: false),
      }),
      isEmpty,
    );
    expect(
      tracker.observe(<int, TorrentInfo>{1: _torrent(id: 1, isFinished: true)}),
      hasLength(1),
    );
    expect(
      tracker.observe(<int, TorrentInfo>{1: _torrent(id: 1, isFinished: true)}),
      isEmpty,
    );
  });

  test('does not emit downloads already finished in the first update', () {
    final tracker = DownloadCompletionTracker();

    expect(
      tracker.observe(<int, TorrentInfo>{1: _torrent(id: 1, isFinished: true)}),
      isEmpty,
    );
  });
}
