import 'dart:io';
import 'package:flutter/foundation.dart';

/// API Endpoint constants
class ApiEndpoints {
  ApiEndpoints._();

  // ── Base ────────────────────────────────────────────────
  // Android Emulator: 10.0.2.2  |  iOS Simulator: 127.0.0.1
 static String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:5000/api';
  }

  if (Platform.isAndroid) {
    return 'http://192.168.1.7:5000/api';
  }

  return 'http://127.0.0.1:5000/api';
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
}
