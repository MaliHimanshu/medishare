import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait-only orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar will be handled by the AppBarTheme automatically

  runApp(const MediShareApp());
}