import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/notification_provider.dart';

// Shared Widgets
import '../../shared/widgets/ms_skeleton.dart';
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
import '../chatbot/chatbot_screen.dart';
import '../search/global_search_screen.dart';
import '../auth/login_screen.dart';
import '../rental/my_rentals_screen.dart';
import '../../core/theme/app_page_transitions.dart';

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

  // Time-based dynamic greeting
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good Morning";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  // Pull-to-refresh
  Future<void> _onRefresh() async {
    await context.read<DashboardProvider>().fetchAll();
  }

  void openFeature(String title) {
    switch (title) {
      case "Donate":
        Navigator.push(context, AppPageTransitions.slideUp(const MyDonationsScreen()));
        break;
      case "Request":
        Navigator.push(context, AppPageTransitions.slideUp(const RequestScreen()));
        break;
      case "Add Equipment":
        Navigator.push(context, AppPageTransitions.slideUp(const AddEquipmentScreen()));
        break;
      case "AI Chat":
        Navigator.push(context, AppPageTransitions.slideUp(const ChatbotScreen()));
        break;
      default:
        break;
    }
  }

  void onBottomTap(int index) {
    setState(() {
      currentIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(context, AppPageTransitions.slideRight(const EquipmentListScreen()));
        break;
      case 2:
        Navigator.push(context, AppPageTransitions.slideUp(const AddEquipmentScreen()));
        break;
      case 3:
        Navigator.push(context, AppPageTransitions.slideRight(const ProfileScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dash = context.watch<DashboardProvider>();
    final user = auth.user;

    final notifProv = context.watch<NotificationProvider>();
    final unreadCount = notifProv.notifications.isNotEmpty
        ? notifProv.unreadCount
        : dash.notifications.where((n) => n['isRead'] == false).length;
    final sum = dash.summary;

    final availableEquipment = sum?['availableEquipment']?.toString() ?? '0';
    final totalRequests = sum?['totalRequests']?.toString() ?? '0';
    final completedDonations = sum?['completedDonations']?.toString() ?? '0';

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
          // AI Chatbot Shortcut
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined, color: AppColors.primary),
            onPressed: () => Navigator.push(context, AppPageTransitions.slideUp(const ChatbotScreen())),
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
      drawer: Drawer(
        backgroundColor: context.surfaceBg,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              accountName: Text(
                user?.name ?? "MediShare User",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
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
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
              title: Text("My Equipment", style: TextStyle(color: context.textPrimaryColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, AppPageTransitions.slideRight(const MyEquipmentScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border_outlined, color: AppColors.primary),
              title: Text("My Donations", style: TextStyle(color: context.textPrimaryColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, AppPageTransitions.slideRight(const MyDonationsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_outlined, color: AppColors.primary),
              title: Text("My Requests", style: TextStyle(color: context.textPrimaryColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, AppPageTransitions.slideRight(const RequestScreen()));
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
              leading: const Icon(Icons.handshake_outlined, color: AppColors.primary),
              title: Text("My Rentals", style: TextStyle(color: context.textPrimaryColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, AppPageTransitions.slideRight(const MyRentalsScreen()));
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
      ),

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
                  
                  // ── Hero Banner ───────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(40),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dynamic Time Greeting & Visual Hierarchy
                        Text(
                          "${_getGreeting()},",
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${user?.name.split(' ').first ?? 'User'}! 👋",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Redistribute medical equipment to build an accessible healthcare network.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Today's dynamic summary badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withAlpha(40), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "TODAY'S SUMMARY",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _SummaryItem(
                                    label: "Available",
                                    value: availableEquipment,
                                    icon: Icons.check_circle_outline,
                                  ),
                                  _SummaryItem(
                                    label: "Requests",
                                    value: totalRequests,
                                    icon: Icons.assignment_outlined,
                                  ),
                                  _SummaryItem(
                                    label: "Donated",
                                    value: completedDonations,
                                    icon: Icons.volunteer_activism_outlined,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Stats Summary 2x2 Grid Section ───────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildStatsGrid(dash),
                  ),
                  const SizedBox(height: 28),

                  // ── Quick Actions Grid ──────────────────────────────
                  Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildQuickActions(),
                  const SizedBox(height: 28),

                  // ── Latest Equipment Slider ─────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Latest Equipment Available",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(context, AppPageTransitions.slideRight(const EquipmentListScreen())),
                        child: const Text("See All", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildEquipmentList(dash),
                  ),
                  const SizedBox(height: 28),

                  // ── Nearby Verified Hospitals ───────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Nearby Hospitals Network",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(context, AppPageTransitions.slideRight(const HospitalScreen())),
                        child: const Text("See All", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildHospitalsList(dash),
                  ),
                  const SizedBox(height: 28),

                  // ── Recent Requests ─────────────────────────────────
                  Text(
                    "Recent Requests Tracking",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
                  ),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildRecentRequests(dash),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),

      // ── Bottom Nav Bar ──────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: context.textSecondaryColor,
        backgroundColor: context.surfaceBg,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        onTap: onBottomTap,
        items: const [
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
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box),
            label: "Donate",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  // ── Stats Summary 2x2 Grid Widget ──────────────────────────────────
  Widget _buildStatsGrid(DashboardProvider dash) {
    if (dash.isLoadingSummary) {
      return Column(
        key: const ValueKey('stats_loading'),
        children: [
          Row(
            children: [
              Expanded(child: MsSkeleton(height: 80)),
              const SizedBox(width: 14),
              Expanded(child: MsSkeleton(height: 80)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: MsSkeleton(height: 80)),
              const SizedBox(width: 14),
              Expanded(child: MsSkeleton(height: 80)),
            ],
          ),
        ],
      );
    }

    final sum = dash.summary;
    final totalListed = sum?['totalEquipment']?.toString() ?? '0';
    final completedDonations = sum?['completedDonations']?.toString() ?? '0';
    final availableEquipment = sum?['availableEquipment']?.toString() ?? '0';
    final totalRequests = sum?['totalRequests']?.toString() ?? '0';

    return Column(
      key: const ValueKey('stats_loaded'),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: "Available",
                value: availableEquipment,
                icon: Icons.check_circle_outline,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatCard(
                title: "Total Listed",
                value: totalListed,
                icon: Icons.inventory_2_outlined,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: "Requests",
                value: totalRequests,
                icon: Icons.assignment_outlined,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatCard(
                title: "Donations",
                value: completedDonations,
                icon: Icons.volunteer_activism_outlined,
                color: Colors.pink,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Quick Actions Row (Donate, Request, Add Equipment, AI Chat) ────────
  Widget _buildQuickActions() {
    final actions = [
      {"title": "Donate", "icon": Icons.favorite_border_outlined, "color": Colors.pink, "action": () => openFeature("Donate")},
      {"title": "Request", "icon": Icons.assignment_outlined, "color": Colors.orange, "action": () => openFeature("Request")},
      {"title": "Add Equipment", "icon": Icons.add_circle_outline, "color": Colors.blue, "action": () => openFeature("Add Equipment")},
      {"title": "AI Chat", "icon": Icons.smart_toy_outlined, "color": Colors.teal, "action": () => openFeature("AI Chat")},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((act) {
        return Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: act["action"] as VoidCallback,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (act["color"] as Color).withAlpha(25),
                        shape: BoxShape.circle,
                        border: Border.all(color: (act["color"] as Color).withAlpha(40), width: 1),
                      ),
                      child: Icon(act["icon"] as IconData, color: act["color"] as Color, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      act["title"] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Equipment Horizontal Slider ────────────────────────────────────
  Widget _buildEquipmentList(DashboardProvider dash) {
    if (dash.isLoadingEquipment) {
      return SizedBox(
        key: const ValueKey('equip_loading'),
        height: 154,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (context, index) => Container(
            margin: const EdgeInsets.only(right: 14),
            child: const MsSkeleton(width: 150, height: 154),
          ),
        ),
      );
    }

    if (dash.equipmentList.isEmpty) {
      return _EmptyState(
        key: const ValueKey('equip_empty'),
        icon: Icons.medical_services_outlined,
        title: "No equipment listed",
        subtitle: "Be the first to list medical equipment and support others.",
        actionLabel: "List Item",
        onAction: () => Navigator.push(context, AppPageTransitions.slideUp(const AddEquipmentScreen())),
        height: 140,
      );
    }

    return SizedBox(
      key: const ValueKey('equip_loaded'),
      height: 154,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dash.equipmentList.length,
        itemBuilder: (context, index) {
          final equip = dash.equipmentList[index];
          return _CustomCard(
            width: 154,
            height: 154,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withAlpha(20),
                  radius: 20,
                  child: const Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  equip.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimaryColor),
                ),
                Text(
                  equip.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.textSecondaryColor, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(35),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        equip.condition,
                        style: const TextStyle(color: AppColors.accentDark, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      "Qty: ${equip.quantity}",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Hospital Slider Widget ─────────────────────────────────────────
  Widget _buildHospitalsList(DashboardProvider dash) {
    if (dash.isLoadingHospitals) {
      return SizedBox(
        key: const ValueKey('hosp_loading'),
        height: 124,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (context, index) => Container(
            margin: const EdgeInsets.only(right: 14),
            child: const MsSkeleton(width: 230, height: 124),
          ),
        ),
      );
    }

    if (dash.hospitals.isEmpty) {
      return _EmptyState(
        key: const ValueKey('hosp_empty'),
        icon: Icons.local_hospital_outlined,
        title: "No nearby hospitals",
        subtitle: "Verified medical centers in your network will appear here.",
        actionLabel: "View Map",
        onAction: () => Navigator.push(context, AppPageTransitions.slideRight(const HospitalScreen())),
        height: 140,
      );
    }

    return SizedBox(
      key: const ValueKey('hosp_loaded'),
      height: 124,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dash.hospitals.length,
        itemBuilder: (context, index) {
          final hosp = dash.hospitals[index];
          return _CustomCard(
            width: 230,
            height: 124,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.red.shade50,
                      radius: 16,
                      child: const Icon(Icons.local_hospital, color: Colors.red, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hosp['hospitalName'] ?? 'Hospital',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.textPrimaryColor),
                      ),
                    )
                  ],
                ),
                Text(
                  hosp['address'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          hosp['city'] ?? '',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
                        ),
                      ],
                    ),
                    Text(
                      "${(index + 1) * 2.2} km",
                      style: const TextStyle(fontSize: 10, color: AppColors.accentDark, fontWeight: FontWeight.bold),
                    )
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Recent Requests Vertical List ──────────────────────────────────
  Widget _buildRecentRequests(DashboardProvider dash) {
    if (dash.isLoadingRequests) {
      return Column(
        key: const ValueKey('req_loading'),
        children: List.generate(2, (_) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: MsSkeleton(height: 74),
        )),
      );
    }

    if (dash.recentRequests.isEmpty) {
      return _EmptyState(
        key: const ValueKey('req_empty'),
        icon: Icons.assignment_outlined,
        title: "No request tracking",
        subtitle: "Active matching requests and listings status will display here.",
        actionLabel: "New Request",
        onAction: () => Navigator.push(context, AppPageTransitions.slideUp(const RequestScreen())),
        height: 140,
      );
    }

    return Column(
      key: const ValueKey('req_loaded'),
      children: dash.recentRequests.map((req) {
        final equip = req['equipment'];
        final requester = req['requester'];
        final status = req['status']?.toString() ?? 'PENDING';

        Color statusColor = Colors.orange;
        if (status == 'APPROVED') {
          statusColor = Colors.green;
        } else if (status == 'REJECTED' || status == 'CANCELLED') {
          statusColor = Colors.red;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(context.isDarkMode ? 30 : 8),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withAlpha(20),
              child: const Icon(Icons.assignment, color: AppColors.primary),
            ),
            title: Text(
              equip?['name'] ?? 'Equipment Item',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimaryColor),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  "From: ${requester?['name'] ?? 'Hospital'}",
                  style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Hero Card Summary Sub-Item ──────────────────────────────────────
class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 9,
              ),
            ),
          ],
        )
      ],
    );
  }
}

// ── Stat Card Widget with Animated Counter ──────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _CustomCard(
      height: 80,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(30),
            radius: 18,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: double.tryParse(value) ?? 0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, child) {
                    return Text(
                      val.toInt().toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.textSecondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ── Reusable Premium Bordered Card (Fully Dynamic Theme) ───────────
class _CustomCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;

  const _CustomCard({
    required this.child,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(context.isDarkMode ? 30 : 6),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: child,
    );
  }
}

// ── Reusable Modern M3 Empty State Widget with Action Button ───────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double height;

  const _EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null && onAction != null;

    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(context.isDarkMode ? 30 : 5),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimaryColor),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: context.textSecondaryColor, height: 1.3),
                ),
                if (hasAction) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: onAction,
                    icon: const Icon(Icons.arrow_forward, size: 14),
                    label: Text(
                      actionLabel!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  )
                ]
              ],
            ),
          )
        ],
      ),
    );
  }
}