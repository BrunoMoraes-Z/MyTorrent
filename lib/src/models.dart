enum TorrentSourceType { magnet, file, url }

enum DownloadStatus { downloading, paused, completed, error, preparing }

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
  });

  final String downloadDirectory;
  final double? downloadLimitMb;
  final double? uploadLimitMb;
  final int metadataTimeoutSeconds;
  final bool restoreOnLaunch;
  final bool notifyOnComplete;

  AppSettings copyWith({
    String? downloadDirectory,
    double? downloadLimitMb,
    double? uploadLimitMb,
    bool clearDownloadLimit = false,
    bool clearUploadLimit = false,
    int? metadataTimeoutSeconds,
    bool? restoreOnLaunch,
    bool? notifyOnComplete,
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
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'downloadDirectory': downloadDirectory,
    'downloadLimitMb': downloadLimitMb,
    'uploadLimitMb': uploadLimitMb,
    'metadataTimeoutSeconds': metadataTimeoutSeconds,
    'restoreOnLaunch': restoreOnLaunch,
    'notifyOnComplete': notifyOnComplete,
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
    );
  }
}
