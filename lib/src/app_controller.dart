import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:libtorrent_flutter/libtorrent_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';
import 'download_destination.dart';
import 'import_detection_service.dart';
import 'settings_store.dart';
import 'torrent_service.dart';

class AppController extends ChangeNotifier {
  AppController._(
    this._settingsStore,
    this._service,
    this._importDetection,
    this.settings,
  );

  final SettingsStore _settingsStore;
  final TorrentService _service;
  final ImportDetectionService _importDetection;
  StreamSubscription<Map<int, TorrentInfo>>? _updatesSubscription;

  AppSettings settings;
  Map<int, TorrentInfo> _downloads = const <int, TorrentInfo>{};
  Object? lastError;

  Stream<ImportCandidate> get importCandidates => _importDetection.candidates;

  List<TorrentInfo> get downloads {
    final values = _downloads.values.toList();
    values.sort((a, b) => b.id.compareTo(a.id));
    return values;
  }

  static Future<AppController> create() async {
    final downloadDirectory = await _defaultDownloadDirectory();
    final supportDirectory = await getApplicationSupportDirectory();
    final store = SettingsStore(supportDirectory);
    final settings = await store.load(downloadDirectory);
    final service = await TorrentService.create(settings.downloadDirectory);
    final importDetection = ImportDetectionService(
      Directory(downloadDirectory),
    );
    await importDetection.start();
    final controller = AppController._(
      store,
      service,
      importDetection,
      settings,
    );
    controller._updatesSubscription = service.updates.listen((items) {
      controller._downloads = items;
      controller.notifyListeners();
    });
    service.setLimits(settings);
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
      throw StateError(
        'Selecione ao menos um arquivo para iniciar o download.',
      );
    }
    final parent = Directory(parentDirectory.trim());
    if (!await parent.exists()) {
      throw FileSystemException('A pasta de destino não existe.', parent.path);
    }
    final directory = DownloadDestination.path(parent.path, folderName);
    await Directory(directory).create(recursive: true);
    if (directory == prepared.directory) {
      _service.start(prepared, selected);
      return;
    }
    _service.cancelPreparation(prepared);
    final relocated = await prepare(
      prepared.source.value,
      directory: directory,
    );
    _service.start(relocated, selected);
  }

  void cancelPreparation(PreparedTorrent prepared) =>
      _service.cancelPreparation(prepared);
  void pause(int id) => _service.pause(id);
  void resume(int id) => _service.resume(id);
  void remove(int id, {required bool deleteFiles}) =>
      _service.remove(id, deleteFiles: deleteFiles);

  Future<void> openFolder(String directory) =>
      Process.start('explorer.exe', <String>[directory]);

  Future<void> saveSettings(AppSettings updated) async {
    final directory = Directory(updated.downloadDirectory);
    if (!await directory.exists()) {
      throw FileSystemException(
        'A pasta de download não existe.',
        directory.path,
      );
    }
    settings = updated;
    _service.setLimits(updated);
    await _settingsStore.save(updated);
    notifyListeners();
  }

  @override
  void dispose() {
    _updatesSubscription?.cancel();
    _importDetection.dispose();
    super.dispose();
  }
}
