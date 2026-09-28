import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/donation_provider.dart';
import '../providers/request_provider.dart';
import '../providers/hospital_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/menu_chatbot_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/global_search_provider.dart';
import '../providers/rental_provider.dart';
import '../providers/tracking_provider.dart';
import '../providers/chat_provider.dart';
import '../features/splash/splash_screen.dart';

import '../core/network/dio_client.dart';
import '../features/auth/login_screen.dart';

class MediShareApp extends StatefulWidget {
  const MediShareApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<MediShareApp> createState() => _MediShareAppState();
}

class _MediShareAppState extends State<MediShareApp> {
  @override
  void initState() {
    super.initState();
    DioClient.onUnauthorized = () {
      final context = MediShareApp.navigatorKey.currentContext;
      if (context != null) {
        try {
          Provider.of<AuthProvider>(context, listen: false).logout();
        } catch (_) {}
      }
      MediShareApp.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<DashboardProvider>(create: (_) => DashboardProvider()),
        ChangeNotifierProvider<EquipmentProvider>(create: (_) => EquipmentProvider()),
        ChangeNotifierProvider<DonationProvider>(create: (_) => DonationProvider()),
        ChangeNotifierProvider<RequestProvider>(create: (_) => RequestProvider()),
        ChangeNotifierProvider<HospitalProvider>(create: (_) => HospitalProvider()),
        ChangeNotifierProvider<NotificationProvider>(create: (_) => NotificationProvider()),
        ChangeNotifierProvider<MenuChatbotProvider>(create: (_) => MenuChatbotProvider()),
        ChangeNotifierProvider<ProfileProvider>(create: (_) => ProfileProvider()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<GlobalSearchProvider>(create: (_) => GlobalSearchProvider()),
        ChangeNotifierProvider<RentalProvider>(create: (_) => RentalProvider()),
        ChangeNotifierProvider<TrackingProvider>(create: (_) => TrackingProvider()),
        ChangeNotifierProvider<ChatProvider>(create: (_) => ChatProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProv, child) {
          return MaterialApp(
            navigatorKey: MediShareApp.navigatorKey,
            debugShowCheckedModeBanner: false,
            title: AppStrings.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProv.themeMode,

            // Clamp text scale to prevent overflow on accessibility font sizes
            builder: (context, widget) {
              final mediaQuery = MediaQuery.of(context);
              final clampedTextScaler = mediaQuery.textScaler.clamp(
                minScaleFactor: 0.8,
                maxScaleFactor: 1.2,
              );
              return MediaQuery(
                data: mediaQuery.copyWith(textScaler: clampedTextScaler),
                child: widget ?? const SizedBox.shrink(),
              );
            },

            // Consistent scroll physics across platforms
            scrollBehavior: const MaterialScrollBehavior(),

            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}