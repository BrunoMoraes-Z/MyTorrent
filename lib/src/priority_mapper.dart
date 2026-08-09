import 'models.dart';

List<int> mapFilePriorities(
  List<DownloadFile> files,
  Set<int> selectedIndexes,
) {
  return files
      .map((file) => selectedIndexes.contains(file.index) ? 1 : 0)
      .toList(growable: false);
}
