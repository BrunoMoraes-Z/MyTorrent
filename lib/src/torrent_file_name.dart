String torrentFileName(String path) {
  final separator = RegExp(r'[\\/]');
  final parts = path.split(separator).where((part) => part.isNotEmpty);
  return parts.isEmpty ? path : parts.last;
}
