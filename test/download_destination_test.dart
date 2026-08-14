import 'package:flutter_test/flutter_test.dart';
import 'package:my_torrent/src/app_error.dart';
import 'package:my_torrent/src/download_destination.dart';

void main() {
  test('uses the selected directory without adding a torrent root', () {
    expect(
      DownloadDestination.savePath(r' C:\Downloads\Custom '),
      r'C:\Downloads\Custom',
    );
  });

  test('rejects an empty download directory', () {
    expect(
      () => DownloadDestination.savePath(' '),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          AppErrorCode.destinationNotFound,
        ),
      ),
    );
  });
}
