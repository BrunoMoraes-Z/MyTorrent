import 'dart:convert';

import 'import_detection_service.dart';

String encodeImportCandidate(ImportCandidate candidate) =>
    jsonEncode(<String, String>{
      'type': candidate.type.name,
      'source': candidate.source,
      'label': candidate.label,
    });

ImportCandidate? decodeImportCandidate(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  try {
    final json = jsonDecode(payload);
    if (json is! Map<String, Object?>) return null;
    final type = switch (json['type']) {
      'torrentFile' => ImportCandidateType.torrentFile,
      'magnet' => ImportCandidateType.magnet,
      _ => null,
    };
    final source = json['source'];
    final label = json['label'];
    if (type == null ||
        source is! String ||
        source.isEmpty ||
        label is! String) {
      return null;
    }
    return ImportCandidate(type: type, source: source, label: label);
  } on FormatException {
    return null;
  }
}
