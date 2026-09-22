import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/notification_provider.dart';

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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
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
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.9, curve: Curves.easeOutCubic)),
    );
    
    // Initialise API fetches
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchAll();
      context.read<NotificationProvider>().fetchNotifications();
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
            Navigator.push(context, AppPageTransitions.slideRight(const MyEquipmentScreen()));
            break;
          case 2:
            Navigator.push(context, AppPageTransitions.slideUp(const AddEquipmentScreen()));
            break;
          case 3:
            Navigator.push(context, AppPageTransitions.slideUp(const MessagesScreen()));
            break;
          case 4:
            Navigator.push(context, AppPageTransitions.slideRight(const ProfileScreen()));
            break;
        }
        break;

      case 'NGO':
        // Navigation: Home, Explore, Requests, Chat, Profile
        switch (index) {
          case 1:
            Navigator.push(context, AppPageTransitions.slideRight(const EquipmentListScreen()));
            break;
          case 2:
            Navigator.push(context, AppPageTransitions.slideRight(const RequestScreen()));
            break;
          case 3:
            Navigator.push(context, AppPageTransitions.slideUp(const MessagesScreen()));
            break;
          case 4:
            Navigator.push(context, AppPageTransitions.slideRight(const ProfileScreen()));
            break;
        }
        break;

      case 'HOSPITAL':
        // Navigation: Home, Equipment, Requests, Chat, Profile
        switch (index) {
          case 1:
            Navigator.push(context, AppPageTransitions.slideRight(const MyEquipmentScreen()));
            break;
          case 2:
            Navigator.push(context, AppPageTransitions.slideRight(const RequestScreen()));
            break;
          case 3:
            Navigator.push(context, AppPageTransitions.slideUp(const MessagesScreen()));
            break;
          case 4:
            Navigator.push(context, AppPageTransitions.slideRight(const ProfileScreen()));
            break;
        }
        break;

      case 'RECIPIENT':
        // Navigation: Home, Explore, Rentals, Chat, Profile
        switch (index) {
          case 1:
            Navigator.push(context, AppPageTransitions.slideRight(const EquipmentListScreen()));
            break;
          case 2:
            Navigator.push(context, AppPageTransitions.slideRight(const MyRentalsScreen()));
            break;
          case 3:
            Navigator.push(context, AppPageTransitions.slideUp(const MessagesScreen()));
            break;
          case 4:
            Navigator.push(context, AppPageTransitions.slideRight(const ProfileScreen()));
            break;
        }
        break;

      case 'ADMIN':
      default:
        // Navigation: Home, Equipment, Requests, Chat, Profile
        switch (index) {
          case 1:
            Navigator.push(context, AppPageTransitions.slideRight(const EquipmentListScreen()));
            break;
          case 2:
            Navigator.push(context, AppPageTransitions.slideRight(const RequestScreen()));
            break;
          case 3:
            Navigator.push(context, AppPageTransitions.slideUp(const MessagesScreen()));
            break;
          case 4:
            Navigator.push(context, AppPageTransitions.slideRight(const ProfileScreen()));
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
      default:
        return DonorDashboard(user: user);
    }
  }

  Widget _buildDrawer(BuildContext context, UserModel? user, AuthProvider auth) {
    final role = user?.role.toUpperCase() ?? 'DONOR';

    return Drawer(
      backgroundColor: context.surfaceBg,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            accountName: Row(
              children: [
                Expanded(
                  child: Text(
                    user?.name ?? "MediShare User",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user?.roleLabel ?? "User",
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            accountEmail: Text(
              user?.email ?? "user@medishare.com",
              style: const TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.white,
              child: Text(
                user?.initial ?? "U",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined, color: AppColors.primary),
            title: Text("Home", style: TextStyle(color: context.textPrimaryColor)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.primary),
            title: Text("Profile", style: TextStyle(color: context.textPrimaryColor)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, AppPageTransitions.slideRight(const ProfileScreen()));
            },
          ),
          if (role == 'DONOR' || role == 'HOSPITAL' || role == 'ADMIN')
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
              title: Text(role == 'HOSPITAL' ? "Hospital Equipment" : "My Equipment", style: TextStyle(color: context.textPrimaryColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, AppPageTransitions.slideRight(const MyEquipmentScreen()));
              },
            ),
          if (role == 'NGO' || role == 'RECIPIENT' || role == 'ADMIN')
            ListTile(
              leading: const Icon(Icons.medical_services_outlined, color: AppColors.primary),
              title: Text("Explore Equipment", style: TextStyle(color: context.textPrimaryColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, AppPageTransitions.slideRight(const EquipmentListScreen()));
              },
            ),
          if (role == 'DONOR' || role == 'HOSPITAL' || role == 'ADMIN')
            ListTile(
              leading: const Icon(Icons.add_box_outlined, color: AppColors.primary),
              title: Text("Add Equipment", style: TextStyle(color: context.textPrimaryColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, AppPageTransitions.slideUp(const AddEquipmentScreen()));
              },
            ),
          if (role == 'DONOR' || role == 'NGO' || role == 'HOSPITAL' || role == 'ADMIN')
            ListTile(
              leading: const Icon(Icons.favorite_border_outlined, color: AppColors.primary),
              title: Text(role == 'NGO' ? "Donations Network" : "My Donations", style: TextStyle(color: context.textPrimaryColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, AppPageTransitions.slideRight(const MyDonationsScreen()));
              },
            ),
          if (role == 'NGO' || role == 'HOSPITAL' || role == 'RECIPIENT' || role == 'ADMIN')
            ListTile(
              leading: const Icon(Icons.assignment_outlined, color: AppColors.primary),
              title: Text(role == 'NGO' ? "Equipment Requests" : "My Requests", style: TextStyle(color: context.textPrimaryColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, AppPageTransitions.slideRight(const RequestScreen()));
              },
            ),
          if (role == 'DONOR' || role == 'RECIPIENT' || role == 'HOSPITAL' || role == 'ADMIN')
            ListTile(
              leading: const Icon(Icons.handshake_outlined, color: AppColors.primary),
              title: Text(role == 'DONOR' ? "Rental Requests" : "My Rentals", style: TextStyle(color: context.textPrimaryColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, AppPageTransitions.slideRight(const MyRentalsScreen()));
              },
            ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
            title: Text("Nearby Equipment", style: TextStyle(color: context.textPrimaryColor)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, AppPageTransitions.slideRight(const NearbyEquipmentScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_hospital_outlined, color: AppColors.primary),
            title: Text("Nearby Hospitals", style: TextStyle(color: context.textPrimaryColor)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, AppPageTransitions.slideRight(const HospitalScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: AppColors.primary),
            title: Text("Settings", style: TextStyle(color: context.textPrimaryColor)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, AppPageTransitions.slideRight(const SettingsScreen()));
            },
          ),
          Divider(color: context.borderColor),
          ListTile(
            leading: const Icon(Icons.logout_outlined, color: AppColors.error),
            title: const Text("Logout", style: TextStyle(color: AppColors.error)),
            onTap: () async {
              final navigator = Navigator.of(context);
              Navigator.pop(context);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dash = context.watch<DashboardProvider>();
    final user = auth.user;
    final role = user?.role ?? 'DONOR';

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
            onPressed: () => Navigator.push(context, AppPageTransitions.slideRight(const GlobalSearchScreen())),
          ),
          // Messages Shortcut
          IconButton(
            icon: const Icon(Icons.forum_outlined, color: AppColors.primary),
            tooltip: "Messages",
            onPressed: () => Navigator.push(context, AppPageTransitions.slideUp(const MessagesScreen())),
          ),
          // Animated Notifications Icon Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: AppColors.primary),
                onPressed: () => Navigator.push(context, AppPageTransitions.slideUp(const NotificationScreen())),
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
              )
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
                  if (user != null && !user.phoneVerified && user.phone != null && user.phone!.isNotEmpty) ...[
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
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
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
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF97316), size: 22),
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
              onPressed: () {
                context.read<AuthProvider>().sendOtp(phone);
                Navigator.push(
                  context,
                  AppPageTransitions.slideRight(OtpVerificationScreen(phone: phone)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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