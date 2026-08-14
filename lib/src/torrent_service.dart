import 'dart:async';
import 'dart:io';

import 'package:libtorrent_flutter/libtorrent_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';
import 'app_error.dart';
import 'download_destination.dart';
import 'priority_mapper.dart';
import 'source_parser.dart';
import 'torrent_file_name.dart';

class PreparedTorrent {
  const PreparedTorrent({
    required this.id,
    required this.source,
    required this.files,
    required this.directory,
    required this.name,
    required this.usesTorrentRoot,
  });

  final int id;
  final TorrentSource source;
  final List<DownloadFile> files;
  final String directory;
  final String name;
  final bool usesTorrentRoot;
}

class TorrentService {
  TorrentService._(this._engine, this._parser);

  final LibtorrentFlutter _engine;
  final TorrentSourceParser _parser;

  Stream<Map<int, TorrentInfo>> get updates => _engine.torrentUpdates;
  Map<int, TorrentInfo> get torrents => _engine.torrents;

  static Future<TorrentService> create(
    String defaultDirectory,
    AppSettings settings,
  ) async {
    await LibtorrentFlutter.init(
      defaultSavePath: defaultDirectory,
      fetchTrackers: settings.fetchTrackers,
      pollInterval: const Duration(milliseconds: 500),
    );
    final engine = LibtorrentFlutter.instance;
    engine.configureSession(
      sessionConfiguration(engine.getDefaultConfig(), settings.enableDht),
    );
    return TorrentService._(engine, const TorrentSourceParser());
  }

  static BtConfig sessionConfiguration(
    BtConfig configuration,
    bool enableDht,
  ) => configuration.copyWith(disableDht: !enableDht, disableUpnp: true);

  Future<PreparedTorrent> prepare(
    String rawSource,
    String directory,
    Duration timeout,
  ) async {
    final source = _parser.parse(rawSource);
    final id = await _addAsPaused(source, directory, timeout);
    try {
      await _waitForMetadata(id, timeout);
      final files = _engine
          .getFiles(id)
          .map(
            (file) => DownloadFile(
              index: file.index,
              name: torrentFileName(file.path.isEmpty ? file.name : file.path),
              size: file.size,
            ),
          )
          .toList(growable: false);
      if (files.isEmpty) {
        throw const AppException(AppErrorCode.noSelectableFiles);
      }
      return PreparedTorrent(
        id: id,
        source: source,
        files: files,
        directory: directory,
        name: DownloadDestination.suggestedFolderName(
          _engine.torrents[id]?.name ?? files.first.name,
        ),
        usesTorrentRoot: files.length > 1,
      );
    } catch (_) {
      _engine.removeTorrent(id, deleteFiles: false);
      rethrow;
    }
  }

  Future<int> _addAsPaused(
    TorrentSource source,
    String directory,
    Duration timeout,
  ) async {
    return switch (source.type) {
      TorrentSourceType.magnet => _engine.addMagnet(
        source.value,
        directory,
        true,
      ),
      TorrentSourceType.file => _engine.addTorrentFile(
        source.value,
        directory,
        true,
      ),
      TorrentSourceType.url => _engine.addTorrentFile(
        await _downloadTorrentFile(Uri.parse(source.value), timeout),
        directory,
        true,
      ),
    };
  }

  Future<void> _waitForMetadata(int id, Duration timeout) async {
    if (_engine.torrents[id]?.hasMetadata ?? false) return;
    await _engine.torrentUpdates
        .where((items) => items[id]?.hasMetadata ?? false)
        .first
        .timeout(
          timeout,
          onTimeout: () =>
              throw const AppException(AppErrorCode.metadataTimeout),
        );
  }

  Future<String> _downloadTorrentFile(Uri uri, Duration timeout) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      final response = await request.close().timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
          AppErrorCode.httpStatus,
          statusCode: response.statusCode,
        );
      }
      if (response.contentLength > 10 * 1024 * 1024) {
        throw const AppException(AppErrorCode.torrentFileTooLarge);
      }
      final cache = await getTemporaryDirectory();
      final target = File(
        '${cache.path}${Platform.pathSeparator}torrent_${DateTime.now().microsecondsSinceEpoch}.torrent',
      );
      final sink = target.openWrite();
      await response.pipe(sink).timeout(timeout);
      return target.path;
    } finally {
      client.close(force: true);
    }
  }

  void start(PreparedTorrent prepared, Set<int> selectedIndexes) {
    setFilePriorities(prepared, selectedIndexes);
    _engine.resumeTorrent(prepared.id);
  }

  void setFilePriorities(PreparedTorrent prepared, Set<int> selectedIndexes) =>
      _engine.setFilePriorities(
        prepared.id,
        mapFilePriorities(prepared.files, selectedIndexes),
      );

  void cancelPreparation(PreparedTorrent prepared) {
    _engine.removeTorrent(prepared.id, deleteFiles: false);
  }

  void pause(int id) => _engine.pauseTorrent(id);
  void resume(int id) => _engine.resumeTorrent(id);
  void recheck(int id) => _engine.recheckTorrent(id);
  void remove(int id, {required bool deleteFiles}) =>
      _engine.removeTorrent(id, deleteFiles: deleteFiles);

  void setLimits(AppSettings settings) {
    _engine.setDownloadLimit(_toBytes(settings.downloadLimitMb));
    _engine.setUploadLimit(_toBytes(settings.uploadLimitMb));
  }

  void setDhtEnabled(bool enabled) {
    _engine.configureSession(
      sessionConfiguration(_engine.getDefaultConfig(), enabled),
    );
  }

  int _toBytes(double? megabytes) =>
      megabytes == null ? 0 : (megabytes * 1024 * 1024).round();
}
