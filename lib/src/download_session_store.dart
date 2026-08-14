import 'dart:convert';
import 'dart:io';

import 'models.dart';

class DownloadSessionSnapshot {
  const DownloadSessionSnapshot({
    this.sessions = const <DownloadSession>[],
    this.completedDownloads = const <CompletedDownload>[],
    this.restartRequested = false,
  });

  final List<DownloadSession> sessions;
  final List<CompletedDownload> completedDownloads;
  final bool restartRequested;

  DownloadSessionSnapshot copyWith({
    List<DownloadSession>? sessions,
    List<CompletedDownload>? completedDownloads,
    bool? restartRequested,
  }) => DownloadSessionSnapshot(
    sessions: sessions ?? this.sessions,
    completedDownloads: completedDownloads ?? this.completedDownloads,
    restartRequested: restartRequested ?? this.restartRequested,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'restartRequested': restartRequested,
    'sessions': sessions.map((session) => session.toJson()).toList(),
    'completedDownloads': completedDownloads
        .map((download) => download.toJson())
        .toList(),
  };

  factory DownloadSessionSnapshot.fromJson(Map<String, Object?> json) {
    final rawSessions = json['sessions'];
    if (rawSessions is! List) {
      throw const FormatException('Lista de sessões inválida.');
    }
    final rawCompletedDownloads =
        json['completedDownloads'] ?? const <Object?>[];
    if (rawCompletedDownloads is! List) {
      throw const FormatException('Lista de downloads concluídos inválida.');
    }
    return DownloadSessionSnapshot(
      restartRequested: json['restartRequested'] as bool? ?? false,
      sessions: rawSessions
          .map((value) {
            if (value is! Map) {
              throw const FormatException('Sessão de download inválida.');
            }
            return DownloadSession.fromJson(Map<String, Object?>.from(value));
          })
          .toList(growable: false),
      completedDownloads: rawCompletedDownloads
          .map((value) {
            if (value is! Map) {
              throw const FormatException('Download concluído inválido.');
            }
            return CompletedDownload.fromJson(Map<String, Object?>.from(value));
          })
          .toList(growable: false),
    );
  }
}

class DownloadSessionStore {
  DownloadSessionStore(this._directory);

  final Directory _directory;

  File get _file =>
      File('${_directory.path}${Platform.pathSeparator}download_sessions.json');

  Future<DownloadSessionSnapshot> load() async {
    try {
      final content = await _file.readAsString();
      return DownloadSessionSnapshot.fromJson(
        jsonDecode(content) as Map<String, Object?>,
      );
    } on FileSystemException {
      return const DownloadSessionSnapshot();
    } on FormatException {
      return const DownloadSessionSnapshot();
    } on TypeError {
      return const DownloadSessionSnapshot();
    }
  }

  Future<void> save(DownloadSessionSnapshot snapshot) async {
    await _directory.create(recursive: true);
    final temporary = File('${_file.path}.tmp');
    await temporary.writeAsString(jsonEncode(snapshot.toJson()), flush: true);
    await temporary.rename(_file.path);
  }
}
