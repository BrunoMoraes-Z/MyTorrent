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

  AppSettings settings;
  Map<int, TorrentInfo> _downloads = const <int, TorrentInfo>{};
  Object? lastError;

  Stream<ImportCandidate> get importCandidates => _importDetection.candidates;
  Stream<TorrentInfo> get downloadCompletions => _downloadCompletions.stream;

  List<TorrentInfo> get downloads {
    final values = _downloads.values.toList();
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
      if (controller.settings.notifyOnComplete) {
        for (final torrent in completed) {
          controller._downloadCompletions.add(torrent);
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
    final directory = DownloadDestination.savePath(parent.path, folderName);
    await Directory(directory).create(recursive: true);
    if (directory == prepared.directory) {
      await _start(prepared, selected);
      return;
    }
    _service.cancelPreparation(prepared);
    final relocated = await prepare(
      prepared.source.value,
      directory: directory,
    );
    await _start(relocated, selected);
  }

  Future<void> _start(PreparedTorrent prepared, Set<int> selected) async {
    _service.start(prepared, selected);
    final session = DownloadSession(
      source: prepared.source.value,
      directory: prepared.directory,
      selectedIndexes: selected.toList()..sort(),
      resumeOnLaunch: true,
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
    _service.remove(id, deleteFiles: deleteFiles);
    final session = _activeSessions.remove(id);
    if (session != null) {
      _savedSessions.remove(session);
      await _saveSessions();
    }
  }

  Future<void> openFolder(String directory) =>
      Process.start('explorer.exe', <String>[directory]);

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
        _activeSessions[prepared.id] = session;
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
