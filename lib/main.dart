import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

import 'services/crashlytics_service.dart';
import 'services/analytics_service.dart';
import 'services/remote_config_service.dart';
import 'core/services/fcm_service.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // 1. Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('[Firebase] Initialized: ${DefaultFirebaseOptions.currentPlatform.projectId}');

      // 2. Initialize Crashlytics (captures all errors after this point)
      await CrashlyticsService.instance.init();

      // 3. Firebase App Check (debug provider in debug, Play Integrity in release)
      try {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
        );
        debugPrint('[APPCHECK] initialization status: SUCCESS');
      } catch (e) {
        debugPrint('[APPCHECK] initialization status: FAILED ($e)');
      }

      // 4. Initialize Analytics
      await AnalyticsService.instance.init();

      // 5. Remote Config
      await RemoteConfigService.instance.init();

      // 6. FCM
      await FcmService().init();

      // 7. Portrait-only orientation
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      runApp(const MediShareApp());
    },
    (error, stackTrace) {
      debugPrint('[main] Unhandled error: $error');
      CrashlyticsService.instance.logError(error, stackTrace, fatal: true);
    },
  );
}
