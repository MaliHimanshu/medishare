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
    
    final navigator = Navigator.of(context);
    
    try {
      if (context.mounted) {
        // Disconnect sockets, stop tracking, clear local provider state
        context.read<ProfileProvider>().clear();
        context.read<EquipmentProvider>().clear();
        context.read<DonationProvider>().clear();
        context.read<RequestProvider>().clear();
        context.read<HospitalProvider>().clear();
        context.read<NotificationProvider>().clear();
        context.read<MenuChatbotProvider>().clear();
        context.read<ChatbotProvider>().clear();
        context.read<GlobalSearchProvider>().clear();
        context.read<RentalProvider>().clear();
        context.read<TrackingProvider>().clear();
        context.read<ChatProvider>().clear();
        context.read<EmergencyAlertProvider>().clear();
        context.read<DashboardProvider>().clear();
      }
      
      final auth = context.read<AuthProvider>();
      await auth.logout(); // This clears cached role/user and calls Firebase signOut
      
      navigator.pushAndRemoveUntil(
        AppPageTransitions.slideRight(const LoginScreen()),
        (route) => false, // Remove authenticated navigation history
      );
    } catch (e) {
      debugPrint('[LOGOUT] performLogout error: $e');
      // Force navigation to login on error
      navigator.pushAndRemoveUntil(
        AppPageTransitions.slideRight(const LoginScreen()),
        (route) => false,
      );
    } finally {
      _isLoggingOut = false;
    }
  }
}
