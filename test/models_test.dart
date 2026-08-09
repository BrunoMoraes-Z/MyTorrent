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
      expect(restored.enableDht, isFalse);
      expect(restored.fetchTrackers, isFalse);
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
