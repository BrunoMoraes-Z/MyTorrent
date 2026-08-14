import 'package:flutter_test/flutter_test.dart';
import 'package:my_torrent/src/import_candidate_payload.dart';
import 'package:my_torrent/src/import_detection_service.dart';

void main() {
  test('round-trips a detected import candidate for a notification', () {
    const candidate = ImportCandidate(
      type: ImportCandidateType.magnet,
      source: 'magnet:?xt=urn:btih:abcdef',
      label: 'magnet:?xt=urn:btih:abcdef',
    );

    final decoded = decodeImportCandidate(encodeImportCandidate(candidate));

    expect(decoded?.type, ImportCandidateType.magnet);
    expect(decoded?.source, candidate.source);
    expect(decoded?.label, candidate.label);
  });

  test('rejects malformed notification payloads', () {
    expect(decodeImportCandidate('{'), isNull);
    expect(decodeImportCandidate('{"type":"magnet"}'), isNull);
  });
}
