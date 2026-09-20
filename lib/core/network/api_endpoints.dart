import 'dart:io';
import 'package:flutter/foundation.dart';

/// API Endpoint constants
class ApiEndpoints {
  ApiEndpoints._();

  // ── Base ────────────────────────────────────────────────
  // Android Emulator: 10.0.2.2  |  iOS Simulator: 127.0.0.1
  // Production Render API: https://medishare-zgmj.onrender.com/api
  // Local Dev (Physical Phone): change _localDevUrl to your laptop's Wi-Fi IPv4 (e.g., http://192.168.1.7:5000/api)
  static const String _liveUrl     = 'https://medishare-zgmj.onrender.com/api';
  static const String _localDevUrl = 'http://192.168.1.7:5000/api';

  // Set to true to use the live Render API (physical device without local backend)
  static const bool _useLiveApi = false;

  static String get baseUrl {
    if (_useLiveApi) return _liveUrl;

    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }

    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2; for physical device change _localDevUrl above
      return kDebugMode ? 'http://10.0.2.2:5000/api' : _liveUrl;
    }

    // iOS Simulator / macOS
    return _localDevUrl.replaceAll('192.168.1.7', '127.0.0.1');
  }

  // ── Auth ────────────────────────────────────────────────
  static const String register = '/auth/register';
  static const String login    = '/auth/login';
  static const String me       = '/auth/me';
  static const String sendOtp  = '/auth/send-otp';
  static const String verifyOtp= '/auth/verify-otp';
  static const String resendOtp= '/auth/resend-otp';

  // ── Equipment ───────────────────────────────────────────
  static const String equipment = '/equipment';

  // ── Donation ────────────────────────────────────────────
  static const String donation = '/donation';

  // ── Request ─────────────────────────────────────────────
  static const String request = '/request';

  // ── Hospital ────────────────────────────────────────────
  static const String hospital = '/hospital';

  // ── Notifications ───────────────────────────────────────
  static const String notifications = '/notification';

  // ── Dashboard ───────────────────────────────────────────
  static const String dashboard = '/dashboard';
  static const String summary = '/dashboard/summary';
  static const String recentRequests = '/dashboard/recent-requests';
  static const String recentDonations = '/dashboard/recent-donations';
  static const String recentNotifications = '/dashboard/recent-notifications';

  // ── Profile ─────────────────────────────────────────────
  static const String profile = '/profile';

  // ── Chatbot ─────────────────────────────────────────────
  static const String chatbot = '/chatbot';

  // ── Upload ──────────────────────────────────────────────
  static const String upload = '/upload';

  // ── Equipment Location (Nearby) ─────────────────────────
  static const String nearbyEquipment = '/equipment/nearby';

  // ── Rental ──────────────────────────────────────────────
  static const String rental           = '/rental';
  static const String rentalById       = '/rental';       // append /{id}
  static const String createRental     = '/rental';
  static const String updateRentalStatus = '/rental';     // append /{id}/status
  static const String rentalPayment    = '/rental';       // append /{id}/payment-verify

  // ── Tracking ────────────────────────────────────────────
  static const String tracking        = '/tracking';      // append /{rentalId}/...
}
