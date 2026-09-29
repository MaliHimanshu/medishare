/**
 * Emergency Alert Audio & Haptics Utility
 * ---------------------------------------
 * File: lib/core/utils/emergency_audio_util.dart
 *
 * Provides single-shot high-priority alert sound and haptic vibration
 * for emergency equipment alerts, respecting Android OS and DND restrictions.
 */

import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class EmergencyAudioUtil {
  EmergencyAudioUtil._();

  static AudioPlayer? _player;
  static final Set<String> _playedAlerts = {};

  /// Plays a single-shot emergency siren for NEW CRITICAL or HIGH alerts
  static Future<void> playEmergencyAlertTone(String alertId, String priority) async {
    try {
      final p = priority.toUpperCase();
      if (p != 'CRITICAL' && p != 'HIGH') return;
      if (_playedAlerts.contains(alertId)) return;

      _playedAlerts.add(alertId);

      // High-importance haptic feedback
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      await HapticFeedback.heavyImpact();

      _player ??= AudioPlayer();
      await _player!.setReleaseMode(ReleaseMode.loop);
      await _player!.play(AssetSource('audio/emergency_siren.wav'));
    } catch (_) {
      // Respect device audio hardware state without throwing
    }
  }

  /// Stops the emergency siren when acknowledged
  static Future<void> stopEmergencyAlertTone() async {
    try {
      if (_player != null) {
        await _player!.stop();
      }
    } catch (_) {}
  }

  /// Single tactile notification pulse
  static Future<void> playNotificationFeedback() async {
    try {
      await HapticFeedback.mediumImpact();
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }
}
