import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/fcm_service.dart';
import 'app/app.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize FCM Service
    await FcmService().init();

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
  }, (error, stackTrace) {
    // Catch all unhandled async exceptions globally (physical device crash guard)
    debugPrint('Unhandled error: $error');
    debugPrint('$stackTrace');
  });
}