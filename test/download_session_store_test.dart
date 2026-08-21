import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_torrent/src/download_session_store.dart';
import 'package:my_torrent/src/models.dart';

void main() {
  test('persists restart intent and download sessions atomically', () async {
    final directory = await Directory.systemTemp.createTemp(
      'torrent_session_test_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final store = DownloadSessionStore(directory);
    const first = DownloadSession(
      source: 'magnet:?xt=urn:btih:one',
      directory: r'C:\Downloads\One',
      selectedIndexes: <int>[0],
      resumeOnLaunch: true,
    );
    const second = DownloadSession(
      source: 'magnet:?xt=urn:btih:two',
      directory: r'C:\Downloads\Two',
      selectedIndexes: <int>[1, 2],
      resumeOnLaunch: false,
    );
    const completed = CompletedDownload(
      name: 'Finished',
      directory: r'C:\Downloads\Finished',
      totalSize: 512,
    );

    await store.save(
      const DownloadSessionSnapshot(
        sessions: <DownloadSession>[first],
        restartRequested: true,
      ),
    );
    await store.save(
      const DownloadSessionSnapshot(
        sessions: <DownloadSession>[second],
        completedDownloads: <CompletedDownload>[completed],
        restartRequested: false,
      ),
    );

    final restored = await store.load();

    expect(restored.restartRequested, isFalse);
    expect(restored.sessions, hasLength(1));
    expect(restored.sessions.single.source, second.source);
    expect(restored.sessions.single.selectedIndexes, <int>[1, 2]);
    expect(restored.completedDownloads.single.name, 'Finished');
  });

  test('ignores malformed persisted sessions', () async {
    final directory = await Directory.systemTemp.createTemp(
      'torrent_session_invalid_test_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final target = File(
      '${directory.path}${Platform.pathSeparator}download_sessions.json',
    );
    await target.writeAsString('{"sessions":[{"source":12}]}');

    final restored = await DownloadSessionStore(directory).load();

    expect(restored.sessions, isEmpty);
    expect(restored.restartRequested, isFalse);
  });

  test('removes a restored legacy session from persistence', () async {
    final directory = await Directory.systemTemp.createTemp(
      'torrent_session_remove_test_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final store = DownloadSessionStore(directory);
    const saved = DownloadSession(
      source: 'magnet:?xt=urn:btih:one',
      directory: r'C:\Downloads\One',
      selectedIndexes: <int>[0, 2],
      resumeOnLaunch: true,
      torrentRoot: 'One',
    );
    await store.save(
      const DownloadSessionSnapshot(sessions: <DownloadSession>[saved]),
    );

    final restored = await store.load();
    final active = DownloadSession(
      source: restored.sessions.single.source,
      directory: restored.sessions.single.directory,
      selectedIndexes: restored.sessions.single.selectedIndexes,
      resumeOnLaunch: restored.sessions.single.resumeOnLaunch,
      contentDirectory: restored.sessions.single.directory,
      torrentRoot: restored.sessions.single.torrentRoot,
    );
    final sessions = restored.sessions.toList();

    expect(sessions.remove(active), isTrue);
    await store.save(restored.copyWith(sessions: sessions));

    expect((await store.load()).sessions, isEmpty);
  });

  test('updates resume state for a restored legacy session', () async {
    final directory = await Directory.systemTemp.createTemp(
      'torrent_session_pause_test_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final store = DownloadSessionStore(directory);
    const saved = DownloadSession(
      source: 'magnet:?xt=urn:btih:one',
      directory: r'C:\Downloads\One',
      selectedIndexes: <int>[0],
      resumeOnLaunch: true,
    );
    await store.save(
      const DownloadSessionSnapshot(sessions: <DownloadSession>[saved]),
    );

    final restored = await store.load();
    final active = DownloadSession(
      source: restored.sessions.single.source,
      directory: restored.sessions.single.directory,
      selectedIndexes: restored.sessions.single.selectedIndexes,
      resumeOnLaunch: restored.sessions.single.resumeOnLaunch,
      contentDirectory: restored.sessions.single.directory,
    );
    final sessions = restored.sessions.toList();
    final index = sessions.indexOf(active);

    expect(index, 0);
    sessions[index] = active.copyWith(resumeOnLaunch: false);
    await store.save(restored.copyWith(sessions: sessions));

    expect((await store.load()).sessions.single.resumeOnLaunch, isFalse);
  });
}
