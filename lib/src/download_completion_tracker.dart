import 'package:libtorrent_flutter/libtorrent_flutter.dart';

class DownloadCompletionTracker {
  Map<int, bool> _finished = const <int, bool>{};

  List<TorrentInfo> observe(Map<int, TorrentInfo> torrents) {
    final completed = <TorrentInfo>[];
    for (final torrent in torrents.values) {
      if (_finished[torrent.id] == false && torrent.isFinished) {
        completed.add(torrent);
      }
    }
    _finished = <int, bool>{
      for (final torrent in torrents.values) torrent.id: torrent.isFinished,
    };
    return completed;
  }
}
