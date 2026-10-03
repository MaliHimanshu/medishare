import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Analytics service — tracks meaningful user interactions.
/// Does NOT track passwords, tokens, or private medical data.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> init() async {
    await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);
    debugPrint('[Analytics] Initialized. Collection enabled: ${!kDebugMode}');
  }

  // ── Auth Events ───────────────────────────────────────────────────────────

  Future<void> logLogin({String method = 'email'}) =>
      _log(() => _analytics.logLogin(loginMethod: method));

  Future<void> logRegister({String method = 'email', String? role}) =>
      _log(() => _analytics.logSignUp(signUpMethod: method));

  Future<void> logLogout() =>
      _log(() => _analytics.logEvent(name: 'logout'));

  // ── Equipment Events ──────────────────────────────────────────────────────

  Future<void> logEquipmentView(String equipmentId, String name) =>
      _log(() => _analytics.logViewItem(
            items: [AnalyticsEventItem(itemId: equipmentId, itemName: name)],
          ));

  Future<void> logEquipmentCreate(String mode) =>
      _log(() => _analytics.logEvent(
            name: 'equipment_create',
            parameters: {'mode': mode},
          ));

  Future<void> logEquipmentSearch(String query) =>
      _log(() => _analytics.logSearch(searchTerm: query));

  Future<void> logImageUploadSuccess() =>
      _log(() => _analytics.logEvent(name: 'image_upload_success'));

  Future<void> logImageUploadFailure(String reason) =>
      _log(() => _analytics.logEvent(
            name: 'image_upload_failure',
            parameters: {'reason': reason},
          ));

  // ── Donation / Rental Events ──────────────────────────────────────────────

  Future<void> logDonationRequest(String equipmentId) =>
      _log(() => _analytics.logEvent(
            name: 'donation_request',
            parameters: {'equipment_id': equipmentId},
          ));

  Future<void> logRentalRequest(String equipmentId) =>
      _log(() => _analytics.logEvent(
            name: 'rental_request',
            parameters: {'equipment_id': equipmentId},
          ));

  Future<void> logBookingCreated(String mode) =>
      _log(() => _analytics.logEvent(
            name: 'booking_created',
            parameters: {'mode': mode},
          ));

  // ── Payment Events ────────────────────────────────────────────────────────

  Future<void> logPaymentStarted() =>
      _log(() => _analytics.logEvent(name: 'payment_started'));

  Future<void> logPaymentSuccess() =>
      _log(() => _analytics.logEvent(name: 'payment_success'));

  Future<void> logPaymentFailed(String reason) =>
      _log(() => _analytics.logEvent(
            name: 'payment_failed',
            parameters: {'reason': reason},
          ));

  // ── Chat Events ───────────────────────────────────────────────────────────

  Future<void> logChatOpened() =>
      _log(() => _analytics.logEvent(name: 'chat_opened'));

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> setUserId(String uid) async {
    await _analytics.setUserId(id: uid);
  }

  Future<void> clearUser() async {
    await _analytics.setUserId(id: null);
  }

  Future<void> _log(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e) {
      debugPrint('[Analytics] Failed to log event: $e');
    }
  }
}
