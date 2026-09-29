/**
 * Emergency Alert Audio & Haptics Utility
 * ---------------------------------------
 * File: lib/core/utils/emergency_audio_util.dart
 *
 * Provides single-shot high-priority alert sound and haptic vibration
 * for emergency equipment alerts, respecting Android OS and DND restrictions.
 */

import 'package:flutter/services.dart';

class EmergencyAudioUtil {
  EmergencyAudioUtil._();

  /// Plays a single-shot emergency alert sound and triggers haptic vibration
  static Future<void> playEmergencyAlertTone() async {
    try {
      // High-importance haptic feedback
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      await HapticFeedback.heavyImpact();

      // System high-importance alert tone
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {
      // Respect device audio hardware state without throwing
    }
  }

  /// Single tactile notification pulse
  static Future<void> playNotificationFeedback() async {
    try {
      await HapticFeedback.mediumImpact();
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }
}
