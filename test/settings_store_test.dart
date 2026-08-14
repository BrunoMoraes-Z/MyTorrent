import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_torrent/src/models.dart';
import 'package:my_torrent/src/settings_store.dart';

void main() {
  test('persists settings with an atomic replacement', () async {
    final directory = await Directory.systemTemp.createTemp(
      'torrent_desk_test_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final store = SettingsStore(directory);
    const expected = AppSettings(
      downloadDirectory: r'C:\Downloads',
      downloadLimitMb: 12.5,
      restoreOnLaunch: false,
      sidebarCollapsed: true,
      language: AppLanguage.en,
    );

    await store.save(expected);
    final restored = await store.load(r'C:\Fallback');

    expect(restored.downloadDirectory, expected.downloadDirectory);
    expect(restored.downloadLimitMb, 12.5);
    expect(restored.restoreOnLaunch, isFalse);
    expect(restored.sidebarCollapsed, isTrue);
    expect(restored.language, AppLanguage.en);
    expect(
      File(
        '${directory.path}${Platform.pathSeparator}settings.json',
      ).existsSync(),
      isTrue,
    );
  });
}
