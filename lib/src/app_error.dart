enum AppErrorCode {
  sourceRequired,
  sourceInvalid,
  noSelectableFiles,
  metadataTimeout,
  httpStatus,
  torrentFileTooLarge,
  fileSelectionRequired,
  destinationNotFound,
  downloadFolderInvalid,
  downloadFolderConflict,
  downloadDirectoryNotFound,
}

class AppException implements Exception {
  const AppException(this.code, {this.statusCode});

  final AppErrorCode code;
  final int? statusCode;
}
