import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../features/splash/splash_screen.dart';

class MediShareApp extends StatelessWidget {
  const MediShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,

      theme: AppTheme.lightTheme,

      home: const SplashScreen(),
    );
  }
}