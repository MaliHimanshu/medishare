import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/donation_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/hospital_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/menu_chatbot_provider.dart';
import '../../providers/chatbot_provider.dart';
import '../../providers/global_search_provider.dart';
import '../../providers/rental_provider.dart';
import '../../providers/tracking_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/emergency_alert_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../features/auth/login_screen.dart';
import '../theme/app_page_transitions.dart';

class LogoutHelper {
  static bool _isLoggingOut = false;

  static Future<void> performLogout(BuildContext context) async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    
    debugPrint('[LOGOUT] performLogout started');
    
    try {
      final navigator = Navigator.of(context);
      
      // We must get auth provider first; if it's missing, we have a bigger problem
      final authProv = context.read<AuthProvider>();
      
      // Safely clear other providers (some might be scoped and not present at the root)
      void safeClear<T extends dynamic>(void Function(T) clearFn) {
        try {
          clearFn(context.read<T>());
        } catch (_) {
          // Provider not found in this context, safely ignore
        }
      }
      
      safeClear<ProfileProvider>((p) => p.clear());
      safeClear<EquipmentProvider>((p) => p.clear());
      safeClear<DonationProvider>((p) => p.clear());
      safeClear<RequestProvider>((p) => p.clear());
      safeClear<HospitalProvider>((p) => p.clear());
      safeClear<NotificationProvider>((p) => p.clear());
      safeClear<MenuChatbotProvider>((p) => p.clear());
      safeClear<ChatbotProvider>((p) => p.clear());
      safeClear<GlobalSearchProvider>((p) => p.clear());
      safeClear<RentalProvider>((p) => p.clear());
      safeClear<TrackingProvider>((p) => p.clear());
      safeClear<ChatProvider>((p) => p.clear());
      safeClear<EmergencyAlertProvider>((p) => p.clear());
      safeClear<DashboardProvider>((p) => p.clear());
      
      debugPrint('[LOGOUT] providers cleared safely');
      
      await authProv.logout(); // This clears cached role/user and calls Firebase signOut
      
      debugPrint('[LOGOUT] navigation completed');
      navigator.pushAndRemoveUntil(
        AppPageTransitions.slideRight(const LoginScreen()),
        (route) => false, // Remove authenticated navigation history
      );
    } catch (e) {
      debugPrint('[LOGOUT] performLogout error: $e');
      // Force navigation to login on error
      if (context.mounted) {
         Navigator.of(context).pushAndRemoveUntil(
          AppPageTransitions.slideRight(const LoginScreen()),
          (route) => false,
        );
      }
    } finally {
      _isLoggingOut = false;
    }
  }
}
