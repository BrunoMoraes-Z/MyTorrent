import 'app_error.dart';

class DownloadDestination {
  const DownloadDestination._();

  static String savePath(String value) {
    final path = value.trim();
    if (path.isEmpty) {
      throw const AppException(AppErrorCode.destinationNotFound);
    }
    return path;
  }
}
