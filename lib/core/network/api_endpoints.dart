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
  static const String _localDevUrl = 'http://192.168.1.7:5000/api'; 

  static String get baseUrl {
    // If you are testing the backend on your laptop and using a physical phone,
    // you must change `_liveUrl` to `_localDevUrl` below and ensure your IP is correct.
    
    if (kIsWeb) {
      return _liveUrl;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      // NOTE: Change this to `return _localDevUrl;` if you want to test your local Node.js server!
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
}
