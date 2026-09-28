import 'dart:io';
import 'package:flutter/foundation.dart';

/// API Endpoint constants
class ApiEndpoints {
  ApiEndpoints._();

  // ── Base ────────────────────────────────────────────────
  // Android Emulator: 10.0.2.2  |  iOS Simulator: 127.0.0.1
  // Production Render API: https://medishare-zgmj.onrender.com/api
  // Local Dev (Physical Phone): laptop's Wi-Fi IPv4 address
  static const String _liveUrl     = 'https://medishare-zgmj.onrender.com/api';
  static const String _localDevUrl = 'http://10.124.196.70:5000/api';

  // Set to true to use the live Render API on physical device or emulator
  static const bool _useLiveApi = false;

  // Set to true if testing on a physical mobile phone connected to local backend via Wi-Fi
  static const bool _usePhysicalPhoneLocal = false;

  static String get baseUrl {
    if (_useLiveApi) return _liveUrl;

    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }

    if (Platform.isAndroid) {
      if (_usePhysicalPhoneLocal) {
        return _localDevUrl;
      }
      // Android emulator uses 10.0.2.2
      return kDebugMode ? 'http://10.0.2.2:5000/api' : _liveUrl;
    }

    if (Platform.isWindows || Platform.isLinux) {
      return 'http://localhost:5000/api';
    }

    // iOS Simulator / macOS / physical iOS
    return _usePhysicalPhoneLocal ? _localDevUrl : 'http://localhost:5000/api';
  }

  // ── Auth ────────────────────────────────────────────────
  static const String register               = '/auth/register';
  static const String login                  = '/auth/login';
  static const String me                     = '/auth/me';
  static const String sendOtp                = '/auth/send-otp';
  static const String verifyOtp              = '/auth/verify-otp';
  static const String resendOtp              = '/auth/resend-otp';
  static const String forgotPasswordSendOtp  = '/auth/forgot-password/send-otp';
  static const String forgotPasswordVerifyOtp= '/auth/forgot-password/verify-otp';
  static const String resetPassword          = '/auth/forgot-password/reset-password';

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
