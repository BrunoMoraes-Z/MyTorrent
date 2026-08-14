import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:libtorrent_flutter/libtorrent_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';
import 'app_error.dart';
import 'download_completion_tracker.dart';
import 'download_session_store.dart';
import 'download_destination.dart';
import 'import_detection_service.dart';
import 'settings_store.dart';
import 'torrent_service.dart';
import 'windows/torrent_folder_renamer.dart';

class AppController extends ChangeNotifier {
  AppController._(
    this._settingsStore,
    this._sessionStore,
    this._service,
    this._importDetection,
    this._restartApplication,
    this._updateDesktopLanguage,
    this.settings,
  );

  final SettingsStore _settingsStore;
  final DownloadSessionStore _sessionStore;
  final TorrentService _service;
  final ImportDetectionService _importDetection;
  final DownloadCompletionTracker _completionTracker =
      DownloadCompletionTracker();
  final StreamController<TorrentInfo> _downloadCompletions =
      StreamController<TorrentInfo>.broadcast();
  final Future<void> Function() _restartApplication;
  final Future<void> Function(AppLanguage) _updateDesktopLanguage;
  StreamSubscription<Map<int, TorrentInfo>>? _updatesSubscription;
  final Map<int, DownloadSession> _activeSessions = <int, DownloadSession>{};
  final List<DownloadSession> _savedSessions = <DownloadSession>[];
  final Map<int, TorrentInfo> _completedDownloads = <int, TorrentInfo>{};
  final Map<int, CompletedDownload> _completedRecords =
      <int, CompletedDownload>{};
  final Set<int> _finalizingDownloads = <int>{};
  int _nextCompletedId = -1;

  AppSettings settings;
  Map<int, TorrentInfo> _downloads = const <int, TorrentInfo>{};
  Object? lastError;

  Stream<ImportCandidate> get importCandidates => _importDetection.candidates;
  Stream<TorrentInfo> get downloadCompletions => _downloadCompletions.stream;

  List<TorrentInfo> get downloads {
    final values = <int, TorrentInfo>{
      ..._downloads,
      ..._completedDownloads,
    }.values.toList();
    values.sort((a, b) => b.id.compareTo(a.id));
    return values;
  }

  static Future<AppController> create({
    required Future<void> Function() restartApplication,
    required Future<void> Function(AppLanguage) updateDesktopLanguage,
  }) async {
    final downloadDirectory = await _defaultDownloadDirectory();
    final supportDirectory = await getApplicationSupportDirectory();
    final store = SettingsStore(supportDirectory);
    final settings = await store.load(downloadDirectory);
    final sessionStore = DownloadSessionStore(supportDirectory);
    final sessionSnapshot = await sessionStore.load();
    final service = await TorrentService.create(
      settings.downloadDirectory,
      settings,
    );
    final importDetection = ImportDetectionService(
      Directory(downloadDirectory),
      detectMagnetLinks: settings.detectMagnetLinks,
      detectTorrentFiles: settings.detectTorrentFiles,
    );
    await importDetection.start();
    final controller = AppController._(
      store,
      sessionStore,
      service,
      importDetection,
      restartApplication,
      updateDesktopLanguage,
      settings,
    );
    controller._updatesSubscription = service.updates.listen((items) {
      final completed = controller._completionTracker.observe(items);
      controller._downloads = items;
      for (final torrent in completed) {
        unawaited(controller._finalizeCompletedDownload(torrent));
      }
      for (final torrent in items.values) {
        if (torrent.isFinished &&
            controller._activeSessions[torrent.id]?.rootLinkPath != null) {
          unawaited(controller._finalizeCompletedDownload(torrent));
        }
      }
      controller.notifyListeners();
    });
    service.setLimits(settings);
    unawaited(controller._restoreSessions(sessionSnapshot));
    return controller;
  }

  static Future<String> _defaultDownloadDirectory() async {
    final directory = await getDownloadsDirectory();
    if (directory != null) return directory.path;
    return '${Platform.environment['USERPROFILE'] ?? Directory.current.path}${Platform.pathSeparator}Downloads';
  }

  Future<PreparedTorrent> prepare(String source, {String? directory}) async {
    _importDetection.markHandled(source);
    lastError = null;
    notifyListeners();
    try {
      return await _service.prepare(
        source,
        directory ?? settings.downloadDirectory,
        Duration(seconds: settings.metadataTimeoutSeconds),
      );
    } catch (error) {
      lastError = error;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> start(
    PreparedTorrent prepared,
    Set<int> selected,
    String parentDirectory,
    String folderName,
  ) async {
    if (selected.isEmpty) {
      throw const AppException(AppErrorCode.fileSelectionRequired);
    }
    final parent = Directory(DownloadDestination.basePath(parentDirectory));
    if (!await parent.exists()) {
      throw const AppException(AppErrorCode.destinationNotFound);
    }
    final contentDirectory = DownloadDestination.savePath(
      parent.path,
      folderName,
    );
    final engineDirectory = prepared.usesTorrentRoot
        ? parent.path
        : contentDirectory;
    final active = prepared.directory == engineDirectory
        ? prepared
        : await _relocatePreparation(prepared, engineDirectory);
    if (active.usesTorrentRoot &&
        active.name != folderName.trim() &&
        await Directory(contentDirectory).exists()) {
      if (active.id != prepared.id) _service.cancelPreparation(active);
      throw const AppException(AppErrorCode.downloadFolderConflict);
    }
    await _start(
      active,
      selected,
      contentDirectory: contentDirectory,
      torrentRoot: active.usesTorrentRoot ? active.name : null,
    );
  }

  Future<PreparedTorrent> _relocatePreparation(
    PreparedTorrent prepared,
    String directory,
  ) async {
    _service.cancelPreparation(prepared);
    return prepare(prepared.source.value, directory: directory);
  }

  Future<void> _start(
    PreparedTorrent prepared,
    Set<int> selected, {
    required String contentDirectory,
    String? torrentRoot,
  }) async {
    _service.start(prepared, selected);
    final session = DownloadSession(
      source: prepared.source.value,
      directory: prepared.directory,
      selectedIndexes: selected.toList()..sort(),
      resumeOnLaunch: true,
      contentDirectory: contentDirectory,
      torrentRoot: torrentRoot,
    );
    _activeSessions[prepared.id] = session;
    _savedSessions.add(session);
    await _saveSessions();
  }

  void cancelPreparation(PreparedTorrent prepared) =>
      _service.cancelPreparation(prepared);
  Future<void> pause(int id) async {
    _service.pause(id);
    await _setResumeOnLaunch(id, false);
  }

  Future<void> resume(int id) async {
    _service.resume(id);
    await _setResumeOnLaunch(id, true);
  }

  Future<void> remove(int id, {required bool deleteFiles}) async {
    final completed = _completedDownloads.remove(id);
    if (completed != null) {
      if (deleteFiles) {
        await Directory(completed.savePath).delete(recursive: true);
      }
      _completedRecords.remove(id);
      await _saveSessions();
      notifyListeners();
      return;
    }
    _service.remove(id, deleteFiles: deleteFiles);
    final session = _activeSessions.remove(id);
    if (session != null) {
      _savedSessions.remove(session);
      await _saveSessions();
    }
  }

  Future<void> openFolder(String directory) =>
      Process.start('explorer.exe', <String>[directory]);

  String downloadDirectory(TorrentInfo torrent) =>
      _activeSessions[torrent.id]?.contentDirectory ?? torrent.savePath;

  Future<void> _finalizeCompletedDownload(TorrentInfo torrent) async {
    if (!_finalizingDownloads.add(torrent.id)) return;
    try {
      final session = _activeSessions[torrent.id];
      final destination = session?.contentDirectory;
      final source = session?.torrentRoot == null
          ? null
          : DownloadDestination.savePath(
              session!.directory,
              session.torrentRoot!,
            );
      final shouldFinalize =
          session?.rootLinkPath != null ||
          (source != null &&
              destination != null &&
              !_samePath(source, destination));
      if (!shouldFinalize) {
        _notifyDownloadComplete(torrent);
        return;
      }

      _service.remove(torrent.id, deleteFiles: false);
      _activeSessions.remove(torrent.id);
      _savedSessions.remove(session);
      var completedPath = source ?? torrent.savePath;
      try {
        if (session?.rootLinkPath != null) {
          await TorrentFolderRenamer.removeLegacyLink(session!.rootLinkPath);
          completedPath = destination ?? completedPath;
        } else {
          await TorrentFolderRenamer.rename(
            sourceDirectory: source!,
            destinationDirectory: destination!,
          );
          completedPath = destination;
        }
      } catch (error) {
        lastError = error;
      }
      final archived = torrent.copyWith(
        savePath: completedPath,
        isPaused: true,
      );
      _archiveCompletedDownload(
        archived,
        CompletedDownload(
          name: archived.name,
          directory: completedPath,
          totalSize: archived.totalWanted,
        ),
      );
      await _saveSessions();
      _notifyDownloadComplete(_completedDownloads[archived.id]!);
      notifyListeners();
    } finally {
      _finalizingDownloads.remove(torrent.id);
    }
  }

  void _notifyDownloadComplete(TorrentInfo torrent) {
    if (settings.notifyOnComplete) _downloadCompletions.add(torrent);
  }

  bool _samePath(String first, String second) =>
      first.replaceAll('/', '\\').toLowerCase() ==
      second.replaceAll('/', '\\').toLowerCase();

  void _archiveCompletedDownload(
    TorrentInfo torrent,
    CompletedDownload record, {
    int? id,
  }) {
    final archiveId = id ?? torrent.id;
    _completedDownloads[archiveId] = archiveId == torrent.id
        ? torrent
        : TorrentInfo(
            id: archiveId,
            name: record.name,
            savePath: record.directory,
            errorMsg: '',
            state: TorrentState.finished,
            progress: 1,
            downloadRate: 0,
            uploadRate: 0,
            totalDone: record.totalSize,
            totalWanted: record.totalSize,
            totalUploaded: 0,
            numPeers: 0,
            numSeeds: 0,
            isPaused: true,
            isFinished: true,
            hasMetadata: true,
            queuePosition: -1,
          );
    _completedRecords[archiveId] = record;
  }

  Future<void> saveSettings(AppSettings updated) async {
    final directory = Directory(updated.downloadDirectory);
    if (!await directory.exists()) {
      throw const AppException(AppErrorCode.downloadDirectoryNotFound);
    }
    final dhtChanged = updated.enableDht != settings.enableDht;
    final languageChanged = updated.language != settings.language;
    settings = updated;
    _importDetection.updateSettings(
      detectMagnetLinks: updated.detectMagnetLinks,
      detectTorrentFiles: updated.detectTorrentFiles,
    );
    if (dhtChanged) _service.setDhtEnabled(updated.enableDht);
    _service.setLimits(updated);
    await _settingsStore.save(updated);
    if (languageChanged) {
      await _updateDesktopLanguage(updated.language);
    }
    notifyListeners();
  }

  Future<void> setSidebarCollapsed(bool collapsed) async {
    if (settings.sidebarCollapsed == collapsed) return;
    final updated = settings.copyWith(sidebarCollapsed: collapsed);
    await _settingsStore.save(updated);
    settings = updated;
    notifyListeners();
  }

  Future<void> restartForTrackerSettings() async {
    for (final entry in _activeSessions.entries.toList()) {
      final isPaused =
          _service.torrents[entry.key]?.isPaused ?? !entry.value.resumeOnLaunch;
      _service.pause(entry.key);
      await _setResumeOnLaunch(entry.key, !isPaused, save: false);
    }
    await _saveSessions(restartRequested: true);
    await _restartApplication();
  }

  Future<void> _restoreSessions(DownloadSessionSnapshot snapshot) async {
    _savedSessions.addAll(snapshot.sessions);
    for (final record in snapshot.completedDownloads) {
      _archiveCompletedDownload(
        TorrentInfo(
          id: _nextCompletedId,
          name: record.name,
          savePath: record.directory,
          errorMsg: '',
          state: TorrentState.finished,
          progress: 1,
          downloadRate: 0,
          uploadRate: 0,
          totalDone: record.totalSize,
          totalWanted: record.totalSize,
          totalUploaded: 0,
          numPeers: 0,
          numSeeds: 0,
          isPaused: true,
          isFinished: true,
          hasMetadata: true,
          queuePosition: -1,
        ),
        record,
      );
      _nextCompletedId--;
    }
    if (!settings.restoreOnLaunch && !snapshot.restartRequested) return;
    for (final session in snapshot.sessions) {
      try {
        if (!await Directory(session.directory).exists()) continue;
        final prepared = await _service.prepare(
          session.source,
          session.directory,
          Duration(seconds: settings.metadataTimeoutSeconds),
        );
        final selected = session.selectedIndexes
            .where((index) => prepared.files.any((file) => file.index == index))
            .toSet();
        if (selected.isEmpty) {
          _service.cancelPreparation(prepared);
          continue;
        }
        _service.pause(prepared.id);
        _service.setFilePriorities(prepared, selected);
        _service.recheck(prepared.id);
        if (session.resumeOnLaunch) {
          _service.resume(prepared.id);
        } else {
          _service.pause(prepared.id);
        }
        _activeSessions[prepared.id] = DownloadSession(
          source: session.source,
          directory: prepared.directory,
          selectedIndexes: session.selectedIndexes,
          resumeOnLaunch: session.resumeOnLaunch,
          contentDirectory: session.contentDirectory ?? prepared.directory,
          torrentRoot: session.torrentRoot,
          rootLinkPath: session.rootLinkPath,
        );
      } catch (_) {
        // A missing source must not prevent other persisted downloads restoring.
      }
    }
    if (snapshot.restartRequested) {
      await _saveSessions(restartRequested: false);
    }
  }

  Future<void> _setResumeOnLaunch(
    int id,
    bool resumeOnLaunch, {
    bool save = true,
  }) async {
    final current = _activeSessions[id];
    if (current == null) return;
    final updated = current.copyWith(resumeOnLaunch: resumeOnLaunch);
    _activeSessions[id] = updated;
    final index = _savedSessions.indexOf(current);
    if (index != -1) _savedSessions[index] = updated;
    if (save) await _saveSessions();
  }

  Future<void> _saveSessions({bool restartRequested = false}) =>
      _sessionStore.save(
        DownloadSessionSnapshot(
          sessions: _savedSessions,
          completedDownloads: _completedRecords.values.toList(),
          restartRequested: restartRequested,
        ),
      );

  @override
  void dispose() {
    _updatesSubscription?.cancel();
    _importDetection.dispose();
    unawaited(_downloadCompletions.close());
    super.dispose();
  }
}
