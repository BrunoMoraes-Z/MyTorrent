enum TorrentSourceType { magnet, file, url }

enum DownloadStatus { downloading, paused, completed, error, preparing }

enum AppLanguage {
  ptBr('pt_BR'),
  en('en');

  const AppLanguage(this.persistedValue);

  final String persistedValue;

  static AppLanguage fromPersistedValue(Object? value) => switch (value) {
    'pt_BR' => AppLanguage.ptBr,
    'en' => AppLanguage.en,
    _ => AppLanguage.en,
  };
}

class TorrentSource {
  const TorrentSource({required this.value, required this.type});

  final String value;
  final TorrentSourceType type;
}

class DownloadFile {
  const DownloadFile({
    required this.index,
    required this.name,
    required this.size,
  });

  final int index;
  final String name;
  final int size;
}

class AppSettings {
  const AppSettings({
    required this.downloadDirectory,
    this.downloadLimitMb,
    this.uploadLimitMb,
    this.metadataTimeoutSeconds = 30,
    this.restoreOnLaunch = true,
    this.notifyOnComplete = true,
    this.soundOnImport = true,
    this.soundOnComplete = true,
    this.detectMagnetLinks = true,
    this.detectTorrentFiles = true,
    this.enableDht = false,
    this.fetchTrackers = false,
    this.sidebarCollapsed = false,
    this.language = AppLanguage.en,
  });

  final String downloadDirectory;
  final double? downloadLimitMb;
  final double? uploadLimitMb;
  final int metadataTimeoutSeconds;
  final bool restoreOnLaunch;
  final bool notifyOnComplete;
  final bool soundOnImport;
  final bool soundOnComplete;
  final bool detectMagnetLinks;
  final bool detectTorrentFiles;
  final bool enableDht;
  final bool fetchTrackers;
  final bool sidebarCollapsed;
  final AppLanguage language;

  AppSettings copyWith({
    String? downloadDirectory,
    double? downloadLimitMb,
    double? uploadLimitMb,
    bool clearDownloadLimit = false,
    bool clearUploadLimit = false,
    int? metadataTimeoutSeconds,
    bool? restoreOnLaunch,
    bool? notifyOnComplete,
    bool? soundOnImport,
    bool? soundOnComplete,
    bool? detectMagnetLinks,
    bool? detectTorrentFiles,
    bool? enableDht,
    bool? fetchTrackers,
    bool? sidebarCollapsed,
    AppLanguage? language,
  }) {
    return AppSettings(
      downloadDirectory: downloadDirectory ?? this.downloadDirectory,
      downloadLimitMb: clearDownloadLimit
          ? null
          : downloadLimitMb ?? this.downloadLimitMb,
      uploadLimitMb: clearUploadLimit
          ? null
          : uploadLimitMb ?? this.uploadLimitMb,
      metadataTimeoutSeconds:
          metadataTimeoutSeconds ?? this.metadataTimeoutSeconds,
      restoreOnLaunch: restoreOnLaunch ?? this.restoreOnLaunch,
      notifyOnComplete: notifyOnComplete ?? this.notifyOnComplete,
      soundOnImport: soundOnImport ?? this.soundOnImport,
      soundOnComplete: soundOnComplete ?? this.soundOnComplete,
      detectMagnetLinks: detectMagnetLinks ?? this.detectMagnetLinks,
      detectTorrentFiles: detectTorrentFiles ?? this.detectTorrentFiles,
      enableDht: enableDht ?? this.enableDht,
      fetchTrackers: fetchTrackers ?? this.fetchTrackers,
      sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
      language: language ?? this.language,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'downloadDirectory': downloadDirectory,
    'downloadLimitMb': downloadLimitMb,
    'uploadLimitMb': uploadLimitMb,
    'metadataTimeoutSeconds': metadataTimeoutSeconds,
    'restoreOnLaunch': restoreOnLaunch,
    'notifyOnComplete': notifyOnComplete,
    'soundOnImport': soundOnImport,
    'soundOnComplete': soundOnComplete,
    'detectMagnetLinks': detectMagnetLinks,
    'detectTorrentFiles': detectTorrentFiles,
    'enableDht': enableDht,
    'fetchTrackers': fetchTrackers,
    'sidebarCollapsed': sidebarCollapsed,
    'language': language.persistedValue,
  };

  factory AppSettings.fromJson(Map<String, Object?> json, String fallbackPath) {
    return AppSettings(
      downloadDirectory: json['downloadDirectory'] as String? ?? fallbackPath,
      downloadLimitMb: (json['downloadLimitMb'] as num?)?.toDouble(),
      uploadLimitMb: (json['uploadLimitMb'] as num?)?.toDouble(),
      metadataTimeoutSeconds:
          (json['metadataTimeoutSeconds'] as num?)?.toInt() ?? 30,
      restoreOnLaunch: json['restoreOnLaunch'] as bool? ?? true,
      notifyOnComplete: json['notifyOnComplete'] as bool? ?? true,
      soundOnImport: json['soundOnImport'] as bool? ?? true,
      soundOnComplete: json['soundOnComplete'] as bool? ?? true,
      detectMagnetLinks: json['detectMagnetLinks'] as bool? ?? true,
      detectTorrentFiles: json['detectTorrentFiles'] as bool? ?? true,
      enableDht: json['enableDht'] as bool? ?? false,
      fetchTrackers: json['fetchTrackers'] as bool? ?? false,
      sidebarCollapsed: json['sidebarCollapsed'] as bool? ?? false,
      language: AppLanguage.fromPersistedValue(json['language']),
    );
  }
}

class DownloadSession {
  const DownloadSession({
    required this.source,
    required this.directory,
    required this.selectedIndexes,
    required this.resumeOnLaunch,
    this.contentDirectory,
    this.torrentRoot,
    this.rootLinkPath,
  });

  final String source;
  final String directory;
  final List<int> selectedIndexes;
  final bool resumeOnLaunch;
  final String? contentDirectory;
  final String? torrentRoot;
  final String? rootLinkPath;

  DownloadSession copyWith({bool? resumeOnLaunch}) => DownloadSession(
    source: source,
    directory: directory,
    selectedIndexes: selectedIndexes,
    resumeOnLaunch: resumeOnLaunch ?? this.resumeOnLaunch,
    contentDirectory: contentDirectory,
    torrentRoot: torrentRoot,
    rootLinkPath: rootLinkPath,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadSession &&
          source == other.source &&
          directory == other.directory &&
          _sameIndexes(selectedIndexes, other.selectedIndexes) &&
          resumeOnLaunch == other.resumeOnLaunch &&
          contentDirectory == other.contentDirectory &&
          torrentRoot == other.torrentRoot &&
          rootLinkPath == other.rootLinkPath;

  @override
  int get hashCode => Object.hash(
    source,
    directory,
    Object.hashAll(selectedIndexes),
    resumeOnLaunch,
    contentDirectory,
    torrentRoot,
    rootLinkPath,
  );

  static bool _sameIndexes(List<int> first, List<int> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'source': source,
    'directory': directory,
    'selectedIndexes': selectedIndexes,
    'resumeOnLaunch': resumeOnLaunch,
    'contentDirectory': contentDirectory,
    'torrentRoot': torrentRoot,
    'rootLinkPath': rootLinkPath,
  };

  factory DownloadSession.fromJson(Map<String, Object?> json) {
    final source = json['source'];
    final directory = json['directory'];
    final selectedIndexes = json['selectedIndexes'];
    if (source is! String || directory is! String || selectedIndexes is! List) {
      throw const FormatException('Sessão de download inválida.');
    }
    final indexes = selectedIndexes
        .map((value) {
          if (value is! num || value < 0 || value != value.roundToDouble()) {
            throw const FormatException('Índice de arquivo inválido.');
          }
          return value.toInt();
        })
        .toList(growable: false);
    return DownloadSession(
      source: source,
      directory: directory,
      selectedIndexes: indexes,
      resumeOnLaunch: json['resumeOnLaunch'] as bool? ?? true,
      contentDirectory: json['contentDirectory'] as String?,
      torrentRoot: json['torrentRoot'] as String?,
      rootLinkPath: json['rootLinkPath'] as String?,
    );
  }
}

class CompletedDownload {
  const CompletedDownload({
    required this.name,
    required this.directory,
    required this.totalSize,
  });

  final String name;
  final String directory;
  final int totalSize;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'directory': directory,
    'totalSize': totalSize,
  };

  factory CompletedDownload.fromJson(Map<String, Object?> json) {
    final name = json['name'];
    final directory = json['directory'];
    final totalSize = json['totalSize'];
    if (name is! String ||
        directory is! String ||
        totalSize is! num ||
        totalSize < 0 ||
        totalSize != totalSize.roundToDouble()) {
      throw const FormatException('Download concluído inválido.');
    }
    return CompletedDownload(
      name: name,
      directory: directory,
      totalSize: totalSize.toInt(),
    );
  }
}
