import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crashlytics service — captures errors and non-fatal exceptions.
/// Does NOT send passwords, tokens, or private medical data.
class CrashlyticsService {
  CrashlyticsService._();
  static final CrashlyticsService instance = CrashlyticsService._();

  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  Future<void> init() async {
    // Disable in debug mode for development
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    // Pass Flutter framework errors to Crashlytics
    FlutterError.onError = (FlutterErrorDetails details) {
      _crashlytics.recordFlutterFatalError(details);
    };

    // Pass all other async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    debugPrint('[Crashlytics] Initialized. Collection enabled: ${!kDebugMode}');
  }

  /// Log a non-fatal error (e.g., API failure, image upload failure).
  /// Safe keys only — no passwords, tokens, or medical data.
  void logError(
    dynamic error,
    StackTrace? stack, {
    String? context,
    bool fatal = false,
  }) {
    if (context != null) {
      _crashlytics.setCustomKey('error_context', context);
    }
    _crashlytics.recordError(error, stack, fatal: fatal);
  }

  /// Set safe user identifier (UID only — no email or name).
  void setUserId(String uid) {
    _crashlytics.setUserIdentifier(uid);
  }

  /// Clear user data on logout.
  void clearUser() {
    _crashlytics.setUserIdentifier('');
  }

  /// Add a safe breadcrumb log.
  void log(String message) {
    _crashlytics.log(message);
  }
}
