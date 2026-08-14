import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

enum ImportCandidateType { torrentFile, magnet }

class ImportCandidate {
  const ImportCandidate({
    required this.type,
    required this.source,
    required this.label,
  });

  final ImportCandidateType type;
  final String source;
  final String label;
}

typedef ClipboardTextReader = Future<String?> Function();

class ImportDetectionService {
  ImportDetectionService(
    this._downloadsDirectory, {
    ClipboardTextReader? clipboardReader,
    this.fileInterval = const Duration(seconds: 5),
    this.clipboardInterval = const Duration(seconds: 3),
    this.detectMagnetLinks = true,
    this.detectTorrentFiles = true,
  }) : _clipboardReader = clipboardReader ?? _readClipboardText;

  final Directory _downloadsDirectory;
  final ClipboardTextReader _clipboardReader;
  final Duration fileInterval;
  final Duration clipboardInterval;
  bool detectMagnetLinks;
  bool detectTorrentFiles;
  final Set<String> _handledSources = <String>{};
  final StreamController<ImportCandidate> _candidates =
      StreamController<ImportCandidate>.broadcast();
  Timer? _fileTimer;
  Timer? _clipboardTimer;

  Stream<ImportCandidate> get candidates => _candidates.stream;

  Future<void> start() async {
    if (detectTorrentFiles) await snapshotExistingTorrentFiles();
    _fileTimer = Timer.periodic(fileInterval, (_) => scanTorrentFiles());
    _clipboardTimer = Timer.periodic(
      clipboardInterval,
      (_) => checkClipboard(),
    );
  }

  Future<void> snapshotExistingTorrentFiles() async {
    if (!await _downloadsDirectory.exists()) return;
    await for (final entity in _downloadsDirectory.list()) {
      if (entity is File && _isTorrentFile(entity.path)) {
        _handledSources.add(_fileKey(entity.path));
      }
    }
  }

  Future<void> scanTorrentFiles() async {
    if (!detectTorrentFiles || !await _downloadsDirectory.exists()) return;
    await for (final entity in _downloadsDirectory.list()) {
      if (entity is! File || !_isTorrentFile(entity.path)) continue;
      if (await entity.length() == 0) continue;
      final key = _fileKey(entity.path);
      if (!_handledSources.add(key)) continue;
      _candidates.add(
        ImportCandidate(
          type: ImportCandidateType.torrentFile,
          source: entity.path,
          label: _fileName(entity.path),
        ),
      );
    }
  }

  Future<void> checkClipboard() async {
    if (!detectMagnetLinks) return;
    final value = (await _clipboardReader())?.trim();
    if (value == null || !_isMagnet(value) || !_handledSources.add(value)) {
      return;
    }
    _candidates.add(
      ImportCandidate(
        type: ImportCandidateType.magnet,
        source: value,
        label: _shortenMagnet(value),
      ),
    );
  }

  void markHandled(String source) {
    _handledSources.add(
      _isTorrentFile(source) ? _fileKey(source) : source.trim(),
    );
  }

  void updateSettings({
    required bool detectMagnetLinks,
    required bool detectTorrentFiles,
  }) {
    this.detectMagnetLinks = detectMagnetLinks;
    this.detectTorrentFiles = detectTorrentFiles;
  }

  void dispose() {
    _fileTimer?.cancel();
    _clipboardTimer?.cancel();
    _candidates.close();
  }

  static Future<String?> _readClipboardText() async =>
      (await Clipboard.getData(Clipboard.kTextPlain))?.text;

  static bool _isTorrentFile(String path) =>
      path.toLowerCase().endsWith('.torrent');

  static bool _isMagnet(String value) =>
      Uri.tryParse(value)?.scheme.toLowerCase() == 'magnet';

  static String _fileKey(String path) => File(path).absolute.path.toLowerCase();

  static String _fileName(String path) {
    final separatorIndex = path.lastIndexOf(Platform.pathSeparator);
    return separatorIndex == -1 ? path : path.substring(separatorIndex + 1);
  }

  static String _shortenMagnet(String value) =>
      value.length <= 54 ? value : '${value.substring(0, 51)}...';
}
