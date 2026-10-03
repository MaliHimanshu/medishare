import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Remote Config service — provides safe remote configuration.
/// NEVER stores secrets (JWT_SECRET, API keys, etc.)
class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> init() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode
            ? const Duration(seconds: 0) // Instant fetch in debug
            : const Duration(hours: 1),
      ));

      // Safe default values — no secrets, no credentials
      await _remoteConfig.setDefaults({
        'maintenance_mode': false,
        'minimum_app_version': '1.0.0',
        'chatbot_enabled': true,
        'rental_enabled': true,
        'donation_enabled': true,
        'support_phone': '',
        'featured_equipment_limit': 10,
        'max_image_size_mb': 10,
        'app_announcement': '',
      });

      await _remoteConfig.fetchAndActivate();
      debugPrint('[RemoteConfig] Initialized and activated.');
    } catch (e) {
      debugPrint('[RemoteConfig] Init failed (using defaults): $e');
    }
  }

  // ── Typed Getters ─────────────────────────────────────────────────────────

  bool get maintenanceMode => _remoteConfig.getBool('maintenance_mode');
  String get minimumAppVersion => _remoteConfig.getString('minimum_app_version');
  bool get chatbotEnabled => _remoteConfig.getBool('chatbot_enabled');
  bool get rentalEnabled => _remoteConfig.getBool('rental_enabled');
  bool get donationEnabled => _remoteConfig.getBool('donation_enabled');
  String get supportPhone => _remoteConfig.getString('support_phone');
  int get featuredEquipmentLimit => _remoteConfig.getInt('featured_equipment_limit');
  int get maxImageSizeMb => _remoteConfig.getInt('max_image_size_mb');
  String get appAnnouncement => _remoteConfig.getString('app_announcement');
}
