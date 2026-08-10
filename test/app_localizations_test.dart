import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_torrent/l10n/generated/app_localizations.dart';

void main() {
  test('provides Portuguese and English translations', () {
    final portuguese = lookupAppLocalizations(const Locale('pt', 'BR'));
    final english = lookupAppLocalizations(const Locale('en'));

    expect(portuguese.settings, 'Configurações');
    expect(portuguese.activeDownloads(2), '2 downloads ativos');
    expect(english.settings, 'Settings');
    expect(english.activeDownloads(2), '2 active downloads');
  });
}
