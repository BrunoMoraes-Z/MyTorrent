// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'My Torrent';

  @override
  String get addTorrent => 'Add torrent';

  @override
  String get addTorrentDescription =>
      'Paste a magnet link, .torrent URL, or choose a local file.';

  @override
  String get cancel => 'Cancel';

  @override
  String get continueAction => 'Continue';

  @override
  String get chooseTorrentFile => 'Choose .torrent file';

  @override
  String get prepareTorrentFailed => 'Unable to prepare torrent';

  @override
  String get close => 'Close';

  @override
  String get magnetLinkFound => 'Magnet link found';

  @override
  String get torrentFileFound => '.torrent file found';

  @override
  String get magnetDetected => 'Detected in the clipboard.';

  @override
  String get torrentFileDetected => 'Detected in the Windows Downloads folder.';

  @override
  String get ignore => 'Ignore';

  @override
  String get import => 'Import';

  @override
  String get downloads => 'Downloads';

  @override
  String get settings => 'Settings';

  @override
  String get engineConnected => 'Engine connected';

  @override
  String activeDownloads(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active downloads',
      one: '1 active download',
      zero: 'No active downloads',
    );
    return '$_temp0';
  }

  @override
  String get downloadsIntro => 'Track and manage your torrents.';

  @override
  String get downloading => 'Downloading';

  @override
  String get paused => 'Paused';

  @override
  String get completed => 'Completed';

  @override
  String get noDownloads => 'No downloads yet.';

  @override
  String get tableName => 'NAME';

  @override
  String get tableProgress => 'PROGRESS';

  @override
  String get tableSpeed => 'SPEED';

  @override
  String get tableStatus => 'STATUS';

  @override
  String get tableActions => 'ACTIONS';

  @override
  String get statusError => 'ERROR';

  @override
  String get statusCompleted => 'COMPLETED';

  @override
  String get statusPaused => 'PAUSED';

  @override
  String get statusDownloading => 'DOWNLOADING';

  @override
  String get removeDownload => 'Remove download?';

  @override
  String removeDownloadDescription(String name) {
    return '\"$name\" will be removed from the list.';
  }

  @override
  String get keepFiles => 'Keep files';

  @override
  String get deleteFiles => 'Delete files';

  @override
  String get selectFiles => 'Select files';

  @override
  String torrentFilesFound(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files found in the torrent.',
      one: '1 file found in the torrent.',
      zero: 'No files found in the torrent.',
    );
    return '$_temp0';
  }

  @override
  String get starting => 'Starting...';

  @override
  String get startDownload => 'Start download';

  @override
  String selectedFiles(num selected, num total) {
    return '$selected of $total files selected';
  }

  @override
  String get baseFolder => 'BASE FOLDER';

  @override
  String get downloadFolder => 'FOLDER NAME';

  @override
  String get limitsMustBePositive => 'Limits must be greater than zero.';

  @override
  String get settingsSaved => 'Settings saved.';

  @override
  String restartFailed(String error) {
    return 'Unable to restart the application: $error';
  }

  @override
  String get restartToApply => 'Restart to apply?';

  @override
  String get restartDescription =>
      'Active downloads will be paused, the app will restart, and they will resume automatically.';

  @override
  String get restartNow => 'Restart now';

  @override
  String get settingsIntro =>
      'Control how your torrents are downloaded and stored.';

  @override
  String get downloadLocation => 'Download location';

  @override
  String get downloadLocationDescription =>
      'This directory will be used for new downloads.';

  @override
  String get choose => 'Choose';

  @override
  String get speedLimits => 'Speed limits';

  @override
  String get speedLimitsDescription =>
      'Leave blank to keep global speed unlimited.';

  @override
  String get maximumDownload => 'Maximum download (MB/s)';

  @override
  String get maximumUpload => 'Maximum upload (MB/s)';

  @override
  String get unlimited => 'Unlimited';

  @override
  String get peerDiscovery => 'Peer discovery';

  @override
  String get peerDiscoveryDescription =>
      'Choose how the app finds trackers and peers for new torrents.';

  @override
  String get useDht => 'Use DHT';

  @override
  String get useDhtDescription =>
      'Finds peers on the decentralized public network. It may connect to unknown IP addresses.';

  @override
  String get fetchPublicTrackers => 'Fetch public trackers';

  @override
  String get fetchPublicTrackersDescription =>
      'Downloads a public list on restart. Saving this change pauses and resumes your downloads.';

  @override
  String get behavior => 'Behavior';

  @override
  String get behaviorDescription =>
      'Transfers continue while the app is in the system tray.';

  @override
  String get restoreDownloads => 'Restore downloads on launch';

  @override
  String get notifyOnComplete => 'Notify when a download completes';

  @override
  String get downloadCompletedNotification => 'Download completed';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsDescription =>
      'Choose when My Torrent should get your attention.';

  @override
  String get soundOnImport => 'Sound when a magnet or .torrent is found';

  @override
  String get soundOnComplete => 'Sound when a download completes';

  @override
  String get automaticDetection => 'Automatic detection';

  @override
  String get automaticDetectionDescription =>
      'Look for new items to import without opening the app.';

  @override
  String get detectMagnetLinks => 'Detect magnet links in the clipboard';

  @override
  String get detectTorrentFiles => 'Detect .torrent files in Downloads';

  @override
  String get language => 'Language';

  @override
  String get languageDescription =>
      'Choose the language used by the application.';

  @override
  String get portugueseBrazil => 'Português (Brasil)';

  @override
  String get english => 'English';

  @override
  String get saveSettings => 'Save settings';

  @override
  String get trayOpen => 'Open My Torrent';

  @override
  String get trayExit => 'Exit';

  @override
  String get errorSourceRequired =>
      'Enter a magnet link, URL, or .torrent file.';

  @override
  String get errorSourceInvalid =>
      'Use a magnet link, an HTTP(S) URL, or an existing .torrent file.';

  @override
  String get errorNoSelectableFiles => 'The torrent has no selectable files.';

  @override
  String get errorMetadataTimeout =>
      'Torrent metadata could not be retrieved in time.';

  @override
  String errorHttpStatus(int statusCode) {
    return 'The URL returned HTTP $statusCode.';
  }

  @override
  String get errorTorrentFileTooLarge => 'The .torrent file exceeds 10 MB.';

  @override
  String get errorFileSelectionRequired =>
      'Select at least one file to start the download.';

  @override
  String get errorDestinationNotFound =>
      'The destination folder does not exist.';

  @override
  String get errorDownloadFolderInvalid => 'Enter a valid folder name.';

  @override
  String get errorDownloadFolderConflict =>
      'A folder with the torrent\'s original name already exists in the selected destination.';

  @override
  String get errorDownloadDirectoryNotFound =>
      'The download folder does not exist.';
}
