import 'dart:io';

void main() {
  var file = File(
    r'c:\All Projects 2026\medishare\lib\features\home\home_screen.dart',
  );
  var content = file.readAsStringSync();

  var replacement = r'''  Widget _buildDrawerItem(
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
    final role = user?.role.toUpperCase() ?? 'DONOR';

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
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
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
                              color: Colors.white.withOpacity(0.9),
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
                              color: Colors.white.withOpacity(0.2),
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
                        AppPageTransitions.slideRight(const EquipmentListScreen()),
                      );
                    },
                  ),
                if (role == 'DONOR' || role == 'HOSPITAL' || role == 'ADMIN')
                  _buildDrawerItem(
                    context,
                    icon: Icons.inventory_2_outlined,
                    title: role == 'HOSPITAL' ? "Hospital Equipment" : "My Equipment",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        AppPageTransitions.slideRight(const MyEquipmentScreen()),
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
                if (role == 'DONOR' || role == 'NGO' || role == 'HOSPITAL' || role == 'ADMIN')
                  _buildDrawerItem(
                    context,
                    icon: Icons.favorite_border_outlined,
                    title: role == 'NGO' ? "Donations Network" : "My Donations",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        AppPageTransitions.slideRight(const MyDonationsScreen()),
                      );
                    },
                  ),
                if (role == 'NGO' || role == 'HOSPITAL' || role == 'RECIPIENT' || role == 'ADMIN')
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
                if (role == 'DONOR' || role == 'RECIPIENT' || role == 'HOSPITAL' || role == 'ADMIN')
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
                      AppPageTransitions.slideRight(const NearbyEquipmentScreen()),
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
                    title: role == 'HOSPITAL' ? "Emergency Alerts" : "Emergency Shortages",
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                  icon: Icons.help_outline,
                  title: "Help & Support",
                  onTap: () {
                    Navigator.pop(context);
                    // Add standard navigation placeholder if missing, or ignore
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
                    await auth.logout();
                    if (context.mounted) {
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
  }''';

  var pattern = RegExp(
    r'  Widget _buildDrawer\([\s\S]*?    \);\n  }',
    multiLine: true,
  );
  if (pattern.hasMatch(content)) {
    content = content.replaceFirst(pattern, replacement);
    file.writeAsStringSync(content);
    print("SUCCESS");
  } else {
    print("FAILED");
  }
}
