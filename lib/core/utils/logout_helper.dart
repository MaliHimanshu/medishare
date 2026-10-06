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
    final profileProv = context.read<ProfileProvider>();
    final equipmentProv = context.read<EquipmentProvider>();
    final donationProv = context.read<DonationProvider>();
    final requestProv = context.read<RequestProvider>();
    final hospitalProv = context.read<HospitalProvider>();
    final notifProv = context.read<NotificationProvider>();
    final menuChatbotProv = context.read<MenuChatbotProvider>();
    final chatbotProv = context.read<ChatbotProvider>();
    final globalSearchProv = context.read<GlobalSearchProvider>();
    final rentalProv = context.read<RentalProvider>();
    final trackingProv = context.read<TrackingProvider>();
    final chatProv = context.read<ChatProvider>();
    final emergencyAlertProv = context.read<EmergencyAlertProvider>();
    final dashboardProv = context.read<DashboardProvider>();
    final authProv = context.read<AuthProvider>();
    
    try {
      // Disconnect sockets, stop tracking, clear local provider state
      profileProv.clear();
      equipmentProv.clear();
      donationProv.clear();
      requestProv.clear();
      hospitalProv.clear();
      notifProv.clear();
      menuChatbotProv.clear();
      chatbotProv.clear();
      globalSearchProv.clear();
      rentalProv.clear();
      trackingProv.clear();
      chatProv.clear();
      emergencyAlertProv.clear();
      dashboardProv.clear();
      
      await authProv.logout(); // This clears cached role/user and calls Firebase signOut
      
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
