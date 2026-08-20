import 'dart:io';
import 'package:flutter/foundation.dart';

/// API Endpoint constants
class ApiEndpoints {
  ApiEndpoints._();

  // ── Base ────────────────────────────────────────────────
  // Android Emulator: 10.0.2.2  |  iOS Simulator: 127.0.0.1
  // Production Render API: https://medishare-zgmj.onrender.com/api
  // Local Development (Physical Phone): Replace with your laptop's Wi-Fi IPv4 address (e.g., http://192.168.1.7:5000/api)
  static const String _liveUrl = 'https://medishare-zgmj.onrender.com/api';
  
  // NOTE: Change this to your laptop's local IP address if testing on a physical phone!
  // ignore: unused_field
  static const String _localDevUrl = 'http://192.168.1.7:5000/api';

  static String get baseUrl {
    // If you are testing the backend on your laptop and using a physical phone,
    // switch the return value below to `_localDevUrl` and make sure the IP matches
    // your machine's Wi-Fi address.
    //
    // To use local dev server, uncomment the next line and comment out the live returns:
    // return _localDevUrl;

    if (kIsWeb) {
      return _liveUrl;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      return _liveUrl;
    }

    return _liveUrl;
  }

  // ── Auth ────────────────────────────────────────────────
  static const String register = '/auth/register';
  static const String login    = '/auth/login';
  static const String me       = '/auth/me';

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
