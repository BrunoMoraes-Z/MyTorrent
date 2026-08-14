import 'models.dart';
import 'source_parser.dart';

String? activationSource(Iterable<String> arguments) {
  const parser = TorrentSourceParser();
  for (final argument in arguments) {
    try {
      final source = parser.parse(argument);
      if (source.type == TorrentSourceType.magnet ||
          source.type == TorrentSourceType.file) {
        return source.value;
      }
    } catch (_) {
      // Windows command-line arguments are untrusted activation input.
    }
  }
  return null;
}
