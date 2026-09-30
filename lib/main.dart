import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/fcm_service.dart';
import 'app/app.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e, stack) {
        debugPrint('Failed to initialize Firebase: $e\n$stack');
      }

      // Initialize FCM Service gracefully
      try {
        await FcmService().init();
      } catch (e, stack) {
        debugPrint('Failed to initialize FCM Service: $e\n$stack');
      }

      // Catch Flutter framework errors gracefully
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
      };

      // Portrait-only orientation
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      runApp(const MediShareApp());
    },
    (error, stackTrace) {
      // Catch all unhandled async exceptions globally (physical device crash guard)
      debugPrint('Unhandled error: $error');
      debugPrint('$stackTrace');
    },
  );
}
