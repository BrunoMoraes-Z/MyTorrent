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
  });

  final String source;
  final String directory;
  final List<int> selectedIndexes;
  final bool resumeOnLaunch;

  DownloadSession copyWith({bool? resumeOnLaunch}) => DownloadSession(
    source: source,
    directory: directory,
    selectedIndexes: selectedIndexes,
    resumeOnLaunch: resumeOnLaunch ?? this.resumeOnLaunch,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'source': source,
    'directory': directory,
    'selectedIndexes': selectedIndexes,
    'resumeOnLaunch': resumeOnLaunch,
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
    );
  }
}
