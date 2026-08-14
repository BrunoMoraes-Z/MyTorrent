import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'import_candidate_payload.dart';
import 'import_detection_service.dart';

class ImportNotificationService {
  ImportNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<ImportCandidate> _activations =
      StreamController<ImportCandidate>.broadcast();
  ImportCandidate? _initialCandidate;
  int _nextId = 0;

  Stream<ImportCandidate> get activations => _activations.stream;

  ImportCandidate? takeInitialCandidate() {
    final candidate = _initialCandidate;
    _initialCandidate = null;
    return candidate;
  }

  Future<void> initialize() async {
    if (!Platform.isWindows) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        windows: WindowsInitializationSettings(
          appName: 'My Torrent',
          appUserModelId: 'com.mytorrent.client',
          guid: 'ae3828bd-7355-48b0-93ad-9ccdf972ebea',
        ),
      ),
      onDidReceiveNotificationResponse: _handleResponse,
    );
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _handleCandidate(
        decodeImportCandidate(launchDetails?.notificationResponse?.payload),
      );
    }
  }

  Future<void> showCandidate({
    required ImportCandidate candidate,
    required String title,
    required bool playSound,
  }) async {
    if (!Platform.isWindows) return;
    await _plugin.show(
      id: _nextId++,
      title: title,
      body: candidate.label,
      payload: encodeImportCandidate(candidate),
      notificationDetails: NotificationDetails(
        windows: WindowsNotificationDetails(
          duration: WindowsNotificationDuration.long,
          audio: _audio(playSound),
        ),
      ),
    );
  }

  Future<void> showDownloadComplete({
    required String title,
    required String body,
    required bool playSound,
  }) async {
    if (!Platform.isWindows) return;
    await _plugin.show(
      id: _nextId++,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        windows: WindowsNotificationDetails(audio: _audio(playSound)),
      ),
    );
  }

  WindowsNotificationAudio _audio(bool playSound) => playSound
      ? WindowsNotificationAudio.preset(
          sound: WindowsNotificationSound.defaultSound,
        )
      : WindowsNotificationAudio.silent();

  void _handleResponse(NotificationResponse response) =>
      _handleCandidate(decodeImportCandidate(response.payload));

  void _handleCandidate(ImportCandidate? candidate) {
    if (candidate == null) return;
    if (_activations.hasListener) {
      _activations.add(candidate);
    } else {
      _initialCandidate = candidate;
    }
  }

  Future<void> dispose() => _activations.close();
}
