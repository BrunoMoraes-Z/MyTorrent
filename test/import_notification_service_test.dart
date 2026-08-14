import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_torrent/src/import_notification_service.dart';

void main() {
  test('uses an explicit Windows sound when notifications are enabled', () {
    final audio = notificationAudio(true);

    expect(audio.isSilent, isFalse);
    expect(audio.source, WindowsNotificationSound.im.name);
  });

  test('uses silent audio when notifications are disabled', () {
    final audio = notificationAudio(false);

    expect(audio.isSilent, isTrue);
  });
}
