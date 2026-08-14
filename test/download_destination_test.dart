import 'package:flutter_test/flutter_test.dart';
import 'package:my_torrent/src/app_error.dart';
import 'package:my_torrent/src/download_destination.dart';

void main() {
  test(
    'creates a per-download directory below the selected base directory',
    () {
      expect(
        DownloadDestination.savePath(r' C:\Downloads ', ' Custom '),
        r'C:\Downloads\Custom',
      );
    },
  );

  test('rejects an empty download directory', () {
    expect(
      () => DownloadDestination.basePath(' '),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          AppErrorCode.destinationNotFound,
        ),
      ),
    );
  });

  test('rejects a folder name that can escape the selected base directory', () {
    expect(
      () => DownloadDestination.savePath(r'C:\Downloads', r'..\payload'),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          AppErrorCode.downloadFolderInvalid,
        ),
      ),
    );
  });

  test('rejects Windows reserved folder names', () {
    expect(
      () => DownloadDestination.savePath(r'C:\Downloads', 'CON'),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          AppErrorCode.downloadFolderInvalid,
        ),
      ),
    );
  });

  test('sanitizes a torrent name for the initial folder suggestion', () {
    expect(
      DownloadDestination.suggestedFolderName(' Release: 2026. '),
      'Release_ 2026',
    );
  });
}
