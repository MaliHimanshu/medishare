import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/donation_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/hospital_provider.dart';
import '../../providers/menu_chatbot_provider.dart';
import '../../providers/chatbot_provider.dart';
import '../../providers/global_search_provider.dart';
import '../../providers/rental_provider.dart';
import '../../providers/tracking_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/emergency_alert_provider.dart';

// Models
import '../../models/user_model.dart';

// Shared Widgets
import '../../shared/widgets/ms_logo.dart';
import '../../core/constants/app_colors.dart';

// Feature Screens
import '../equipment/equipment_list_screen.dart';
import '../equipment/add_equipment_screen.dart';
import '../equipment/my_equipment_screen.dart';
import '../equipment/nearby_equipment_screen.dart';
import '../donations/my_donations_screen.dart';
import '../requests/request_screen.dart';
import '../hospital/hospital_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notification_screen.dart';
import '../settings/settings_screen.dart';
import '../chat/messages_screen.dart';
import '../search/global_search_screen.dart';
import '../auth/login_screen.dart';
import '../auth/otp_verification_screen.dart';
import '../rental/my_rentals_screen.dart';
import '../../core/theme/app_page_transitions.dart';
import '../../providers/emergency_alert_provider.dart';
import '../emergency_alerts/hospital_emergency_alerts_screen.dart';
import '../emergency_alerts/ngo_emergency_alerts_screen.dart';

// Role Dashboards
import 'dashboards/donor_dashboard.dart';
import 'dashboards/ngo_dashboard.dart';
import 'dashboards/hospital_dashboard.dart';
import 'dashboards/recipient_dashboard.dart';
import 'dashboards/admin_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.0, 0.9, curve: Curves.easeOutCubic),
          ),
        );

    // Initialise API fetches
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchAll();
      context.read<NotificationProvider>().fetchNotifications();
      final user = context.read<AuthProvider>().user;
      if (user?.role.toUpperCase() == 'HOSPITAL') {
        context.read<EmergencyAlertProvider>().fetchHospitalAlerts();
      } else if (user?.role.toUpperCase() == 'NGO') {
        context.read<EmergencyAlertProvider>().fetchActiveAlerts();
      }
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Pull-to-refresh
  Future<void> _onRefresh() async {
    await context.read<DashboardProvider>().fetchAll();
  }

  void _onBottomTapForRole(int index, String role) {
    if (index == 0) {
      setState(() => currentIndex = 0);
      return;
    }

    switch (role.toUpperCase()) {
      case 'DONOR':
        // Navigation: Home, My Equipment, Add, Chat, Profile
        switch (index) {
          case 1:
            Navigator.push(
              context,
              AppPageTransitions.slideRight(const MyEquipmentScreen()),
            );
            break;
          case 2:
            Navigator.push(
              context,
              AppPageTransitions.slideUp(const AddEquipmentScreen()),
            );
            break;
          case 3:
            Navigator.push(
              context,
              AppPageTransitions.slideUp(const MessagesScreen()),
            );
            break;
          case 4:
            Navigator.push(
              context,
              AppPageTransitions.slideRight(const ProfileScreen()),
            );
            break;
        }
        break;

      case 'NGO':
        // Navigation: Home, Explore, Requests, Chat, Profile
        switch (index) {
          case 1:
            Navigator.push(
              context,
              AppPageTransitions.slideRight(const EquipmentListScreen()),
            );
            break;
          case 2:
            Navigator.push(
              context,
              AppPageTransitions.slideRight(const RequestScreen()),
            );
            break;
          case 3:
            Navigator.push(
              context,
              AppPageTransitions.slideUp(const MessagesScreen()),
            );
            break;
          case 4:
            Navigator.push(
              context,
              AppPageTransitions.slideRight(const ProfileScreen()),
            );
            break;
        }
        break;

      case 'HOSPITAL':
        // Navigation: Home, Equipment, Requests, Chat, Profile
        switch (index) {
          case 1:
            Navigator.push(
              context,
              AppPageTransitions.slideRight(const MyEquipmentScreen()),
            );
            break;
          case 2:
            Navigator.push(
              context,
              AppPageTransitions.slideRight(const RequestScreen()),
            );
            break;
          case 3:
            Navigator.push(
              context,
              AppPageTransitions.slideUp(const MessagesScreen()),
            );
            break;
          case 4:
            Navigator.push(
              context,
              AppPageTransitions.slideRight(const ProfileScreen()),
            );
            break;
        }
        break;

      case 'RECIPIENT':
        // Navigation: Home, Explore, Rentals, Chat, Profile
        switch (index) {
          case 1:
            Navigator.push(
              context,
              AppPageTransitions.slideRight(const EquipmentListScreen()),
            );
            break;
          case 2:
            Navigator.push(
              context,
              AppPageTransitions.slideRight(const MyRentalsScreen()),
            );
            break;
          case 3:
            Navigator.push(
              context,
              AppPageTransitions.slideUp(const MessagesScreen()),
            );
            break;
          case 4:
            Navigator.push(
              context,
              AppPageTransitions.slideRight(const ProfileScreen()),
            );
            break;
        }
        break;

      case 'ADMIN':
      default:
        // Navigation: Home, Equipment, Requests, Chat, Profile
        switch (index) {
          case 1:
            Navigator.push(
              context,
              AppPageTransitions.slideRight(const EquipmentListScreen()),
            );
            break;
          case 2:
            Navigator.push(
              context,
              AppPageTransitions.slideRight(const RequestScreen()),
            );
            break;
          case 3:
            Navigator.push(
              context,
              AppPageTransitions.slideUp(const MessagesScreen()),
            );
            break;
          case 4:
            Navigator.push(
              context,
              AppPageTransitions.slideRight(const ProfileScreen()),
            );
            break;
        }
        break;
    }
  }

  List<BottomNavigationBarItem> _getNavItemsForRole(String role) {
    switch (role.toUpperCase()) {
      case 'DONOR':
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: "My Equipment",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box),
            label: "Add",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            activeIcon: Icon(Icons.forum),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ];

      case 'NGO':
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: "Explore",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: "Requests",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            activeIcon: Icon(Icons.forum),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ];

      case 'HOSPITAL':
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services),
            label: "Equipment",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: "Requests",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            activeIcon: Icon(Icons.forum),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ];

      case 'RECIPIENT':
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: "Explore",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handshake_outlined),
            activeIcon: Icon(Icons.handshake),
            label: "Rentals",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            activeIcon: Icon(Icons.forum),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ];

      case 'ADMIN':
      default:
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services),
            label: "Equipment",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: "Requests",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            activeIcon: Icon(Icons.forum),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ];
    }
  }

  Widget _buildRoleDashboard(UserModel? user) {
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (user.role.toUpperCase()) {
      case 'DONOR':
        return DonorDashboard(user: user);
      case 'NGO':
        return NgoDashboard(user: user);
      case 'HOSPITAL':
        return HospitalDashboard(user: user);
      case 'RECIPIENT':
        return RecipientDashboard(user: user);
      case 'ADMIN':
        return AdminDashboard(user: user);
      case 'UNKNOWN':
        // Role is still being resolved from Firestore — show loader
        return const Center(child: CircularProgressIndicator());
      default:
        return DonorDashboard(user: user);
    }
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor ?? AppColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor ?? context.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, bottom: 8, top: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: context.textSecondaryColor,
        ),
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    UserModel? user,
    AuthProvider auth,
  ) {
    final role = user?.role.toUpperCase() ?? 'UNKNOWN';

    return Drawer(
      backgroundColor: context.surfaceBg,
      child: Column(
        children: [
          // ── Premium Profile Header ──
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        backgroundImage: user?.profileImage != null
                            ? NetworkImage(user!.profileImage!)
                            : null,
                        child: user?.profileImage == null
                            ? Text(
                                user?.initial ?? "U",
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user?.name ?? "MediShare User",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? "user@medishare.com",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user?.roleLabel ?? "User",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Scrollable Menu ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              children: [
                _buildDrawerSectionHeader(context, "Main"),
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  title: "Home",
                  onTap: () => Navigator.pop(context),
                ),

                _buildDrawerSectionHeader(context, "Services"),
                if (role == 'NGO' || role == 'RECIPIENT' || role == 'ADMIN')
                  _buildDrawerItem(
                    context,
                    icon: Icons.medical_services_outlined,
                    title: "Explore Equipment",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        AppPageTransitions.slideRight(
                          const EquipmentListScreen(),
                        ),
                      );
                    },
                  ),
                if (role == 'DONOR' || role == 'HOSPITAL' || role == 'ADMIN')
                  _buildDrawerItem(
                    context,
                    icon: Icons.inventory_2_outlined,
                    title: role == 'HOSPITAL'
                        ? "Hospital Equipment"
                        : "My Equipment",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        AppPageTransitions.slideRight(
                          const MyEquipmentScreen(),
                        ),
                      );
                    },
                  ),
                if (role == 'DONOR' || role == 'HOSPITAL' || role == 'ADMIN')
                  _buildDrawerItem(
                    context,
                    icon: Icons.add_box_outlined,
                    title: "Add Equipment",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        AppPageTransitions.slideUp(const AddEquipmentScreen()),
                      );
                    },
                  ),
                if (role == 'DONOR' ||
                    role == 'NGO' ||
                    role == 'HOSPITAL' ||
                    role == 'ADMIN')
                  _buildDrawerItem(
                    context,
                    icon: Icons.favorite_border_outlined,
                    title: role == 'NGO' ? "Donations Network" : "My Donations",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        AppPageTransitions.slideRight(
                          const MyDonationsScreen(),
                        ),
                      );
                    },
                  ),
                if (role == 'NGO' ||
                    role == 'HOSPITAL' ||
                    role == 'RECIPIENT' ||
                    role == 'ADMIN')
                  _buildDrawerItem(
                    context,
                    icon: Icons.assignment_outlined,
                    title: role == 'NGO' ? "Equipment Requests" : "My Requests",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        AppPageTransitions.slideRight(const RequestScreen()),
                      );
                    },
                  ),
                if (role == 'DONOR' ||
                    role == 'RECIPIENT' ||
                    role == 'HOSPITAL' ||
                    role == 'ADMIN')
                  _buildDrawerItem(
                    context,
                    icon: Icons.handshake_outlined,
                    title: role == 'DONOR' ? "Rental Requests" : "My Rentals",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        AppPageTransitions.slideRight(const MyRentalsScreen()),
                      );
                    },
                  ),
                _buildDrawerItem(
                  context,
                  icon: Icons.location_on_outlined,
                  title: "Nearby Equipment",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      AppPageTransitions.slideRight(
                        const NearbyEquipmentScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.local_hospital_outlined,
                  title: "Nearby Hospitals",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      AppPageTransitions.slideRight(const HospitalScreen()),
                    );
                  },
                ),

                if (role == 'HOSPITAL' || role == 'NGO' || role == 'ADMIN') ...[
                  _buildDrawerSectionHeader(context, "Alerts"),
                  _buildDrawerItem(
                    context,
                    icon: Icons.crisis_alert_rounded,
                    title: role == 'HOSPITAL'
                        ? "Emergency Alerts"
                        : "Emergency Shortages",
                    iconColor: const Color(0xFFDC2626),
                    textColor: const Color(0xFFDC2626),
                    onTap: () {
                      Navigator.pop(context);
                      if (role == 'HOSPITAL' || role == 'ADMIN') {
                        Navigator.push(
                          context,
                          AppPageTransitions.slideRight(
                            const HospitalEmergencyAlertsScreen(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          AppPageTransitions.slideRight(
                            const NgoEmergencyAlertsScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ],

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Divider(color: context.borderColor),
                ),

                _buildDrawerSectionHeader(context, "Account"),
                _buildDrawerItem(
                  context,
                  icon: Icons.person_outline,
                  title: "Profile",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      AppPageTransitions.slideRight(const ProfileScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: "Settings",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      AppPageTransitions.slideRight(const SettingsScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout_outlined,
                  title: "Logout",
                  iconColor: AppColors.error,
                  textColor: AppColors.error,
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    Navigator.pop(context);
                    // ── Clear ALL provider state before logout ────────────
                    // Prevents stale role/data from showing after account switch.
                    if (mounted) {
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
                    await auth.logout();
                    if (mounted) {
                      navigator.pushAndRemoveUntil(
                        AppPageTransitions.slideRight(const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dash = context.watch<DashboardProvider>();
    final user = auth.user;
    final role = user?.role.toUpperCase() ?? 'UNKNOWN';

    final notifProv = context.watch<NotificationProvider>();
    final unreadCount = notifProv.notifications.isNotEmpty
        ? notifProv.unreadCount
        : dash.notifications.where((n) => n['isRead'] == false).length;

    return Scaffold(
      backgroundColor: context.scaffoldBg,

      // ── App Bar ─────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: context.surfaceBg,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        title: const MsLogo(height: 38),
        centerTitle: true,
        actions: [
          // Global Search Shortcut
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.primary),
            onPressed: () => Navigator.push(
              context,
              AppPageTransitions.slideRight(const GlobalSearchScreen()),
            ),
          ),
          // Messages Shortcut
          IconButton(
            icon: const Icon(Icons.forum_outlined, color: AppColors.primary),
            tooltip: "Messages",
            onPressed: () => Navigator.push(
              context,
              AppPageTransitions.slideUp(const MessagesScreen()),
            ),
          ),
          // Animated Notifications Icon Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_outlined,
                  color: AppColors.primary,
                ),
                onPressed: () => Navigator.push(
                  context,
                  AppPageTransitions.slideUp(const NotificationScreen()),
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: AnimatedScale(
                  scale: unreadCount > 0 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

      // ── Drawer ──────────────────────────────────────────
      drawer: _buildDrawer(context, user, auth),

      // ── Body ────────────────────────────────────────────
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Unverified Phone Banner ────────────────────────
                  if (user != null &&
                      !user.phoneVerified &&
                      user.phone != null &&
                      user.phone!.isNotEmpty) ...[
                    _buildUnverifiedPhoneCard(context, user.phone!),
                    const SizedBox(height: 16),
                  ],

                  // ── Role-Based Dashboard ───────────────────────────
                  _buildRoleDashboard(user),
                ],
              ),
            ),
          ),
        ),
      ),

      // ── Role-Based Bottom Navigation Bar ────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: context.textSecondaryColor,
        backgroundColor: context.surfaceBg,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        onTap: (index) => _onBottomTapForRole(index, role),
        items: _getNavItemsForRole(role),
      ),
    );
  }

  Widget _buildUnverifiedPhoneCard(BuildContext context, String phone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        border: Border.all(color: const Color(0xFFFED7AA), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFF97316),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Mobile number not verified",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9A3412),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Verify $phone to secure your account",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFC2410C),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                final messenger = ScaffoldMessenger.of(context);
                final success = await auth.sendOtp(phone);
                if (!context.mounted) return;
                if (success) {
                  Navigator.push(
                    context,
                    AppPageTransitions.slideRight(
                      OtpVerificationScreen(phone: phone),
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(auth.errorMessage ?? 'Failed to send OTP'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size.zero,
              ),
              child: const Text(
                "Verify Now",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
