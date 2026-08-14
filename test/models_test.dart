import 'package:flutter_test/flutter_test.dart';
import 'package:my_torrent/src/models.dart';

void main() {
  group('AppSettings', () {
    test('serializes unlimited speed settings as null', () {
      const settings = AppSettings(downloadDirectory: r'C:\Downloads');
      final restored = AppSettings.fromJson(settings.toJson(), r'C:\Fallback');

      expect(restored.downloadDirectory, r'C:\Downloads');
      expect(restored.downloadLimitMb, isNull);
      expect(restored.uploadLimitMb, isNull);
      expect(restored.restoreOnLaunch, isTrue);
      expect(restored.notifyOnComplete, isTrue);
      expect(restored.soundOnImport, isTrue);
      expect(restored.soundOnComplete, isTrue);
      expect(restored.detectMagnetLinks, isTrue);
      expect(restored.detectTorrentFiles, isTrue);
      expect(restored.enableDht, isFalse);
      expect(restored.fetchTrackers, isFalse);
      expect(restored.sidebarCollapsed, isFalse);
      expect(restored.language, AppLanguage.en);
    });

    test('defaults legacy settings without a language to English', () {
      final restored = AppSettings.fromJson(<String, Object?>{
        'downloadDirectory': r'C:\Downloads',
      }, r'C:\Fallback');

      expect(restored.language, AppLanguage.en);
      expect(restored.soundOnImport, isTrue);
      expect(restored.soundOnComplete, isTrue);
      expect(restored.detectMagnetLinks, isTrue);
      expect(restored.detectTorrentFiles, isTrue);
    });

    test('persists notification and automatic detection preferences', () {
      const settings = AppSettings(
        downloadDirectory: r'C:\Downloads',
        soundOnImport: false,
        soundOnComplete: false,
        detectMagnetLinks: false,
        detectTorrentFiles: false,
      );

      final restored = AppSettings.fromJson(settings.toJson(), r'C:\Fallback');

      expect(restored.soundOnImport, isFalse);
      expect(restored.soundOnComplete, isFalse);
      expect(restored.detectMagnetLinks, isFalse);
      expect(restored.detectTorrentFiles, isFalse);
    });

    test('clears explicit speed limits', () {
      const settings = AppSettings(
        downloadDirectory: r'C:\Downloads',
        downloadLimitMb: 5,
        uploadLimitMb: 1,
      );
      final updated = settings.copyWith(
        clearDownloadLimit: true,
        clearUploadLimit: true,
      );

      expect(updated.downloadLimitMb, isNull);
      expect(updated.uploadLimitMb, isNull);
    });

    test('persists peer discovery preferences', () {
      const settings = AppSettings(
        downloadDirectory: r'C:\Downloads',
        enableDht: true,
        fetchTrackers: true,
      );

      final restored = AppSettings.fromJson(settings.toJson(), r'C:\Fallback');

      expect(restored.enableDht, isTrue);
      expect(restored.fetchTrackers, isTrue);
    });

    test('persists the selected application language', () {
      const settings = AppSettings(
        downloadDirectory: r'C:\Downloads',
        language: AppLanguage.en,
      );

      final restored = AppSettings.fromJson(settings.toJson(), r'C:\Fallback');

      expect(restored.language, AppLanguage.en);
    });

    test('persists the collapsed sidebar preference', () {
      const settings = AppSettings(
        downloadDirectory: r'C:\Downloads',
        sidebarCollapsed: true,
      );

      final restored = AppSettings.fromJson(settings.toJson(), r'C:\Fallback');

      expect(restored.sidebarCollapsed, isTrue);
    });
  });

  group('DownloadSession', () {
    test('serializes selected files and launch state', () {
      const session = DownloadSession(
        source: 'magnet:?xt=urn:btih:abc',
        directory: r'C:\Downloads\Example',
        selectedIndexes: <int>[0, 3],
        resumeOnLaunch: false,
      );

      final restored = DownloadSession.fromJson(session.toJson());

      expect(restored.source, session.source);
      expect(restored.directory, session.directory);
      expect(restored.selectedIndexes, <int>[0, 3]);
      expect(restored.resumeOnLaunch, isFalse);
    });
  });
}
