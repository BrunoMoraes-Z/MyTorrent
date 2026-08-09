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
  });
}
