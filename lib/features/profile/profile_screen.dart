import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../shared/widgets/ms_skeleton.dart';
import '../../shared/widgets/ms_image.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/help_support_screen.dart';
import '../settings/about_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import '../../core/theme/app_page_transitions.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile();
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10),
            Text('Confirm Logout'),
          ],
        ),
        content: const Text('Are you sure you want to log out of your MediShare account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              final navigator = Navigator.of(context);
              Navigator.pop(ctx);

              await authProvider.logout();
              navigator.pushAndRemoveUntil(
                AppPageTransitions.slideRight(const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Delete Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deleting your account will remove your data permanently. Please enter your password to confirm.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final profileProvider = context.read<ProfileProvider>();
              final authProvider = context.read<AuthProvider>();
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              if (passwordCtrl.text.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Password required to delete account.')),
                );
                return;
              }

              Navigator.pop(ctx);
              final success = await profileProvider.deleteAccount(passwordCtrl.text);

              if (mounted) {
                if (success) {
                  await authProvider.logout();
                  navigator.pushAndRemoveUntil(
                    AppPageTransitions.slideRight(const LoginScreen()),
                    (route) => false,
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(content: Text(profileProvider.errorMessage)),
                  );
                }
              }
            },
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();

    final user = profileProvider.user ?? authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                AppPageTransitions.slideRight(const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: profileProvider.isLoading
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                MsSkeleton(height: 180),
                SizedBox(height: 16),
                MsSkeleton(height: 120),
                SizedBox(height: 16),
                MsSkeleton(height: 240),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Profile Header ────────────────────────────────
                  _buildProfileHeader(context, user),

                  const SizedBox(height: 24),

                  // ── Activity Statistics Grid ──────────────────────
                  _buildStatsGrid(context, profileProvider),

                  const SizedBox(height: 24),

                  // ── Account & General Options ─────────────────────
                  Text(
                    'Account & Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Card(
                    elevation: 0,
                    color: context.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: context.borderColor),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.withAlpha(context.isDarkMode ? 40 : 30),
                            child: const Icon(Icons.person_outline, color: Colors.blue),
                          ),
                          title: Text('Edit Profile', style: TextStyle(color: context.textPrimaryColor)),
                          subtitle: Text('Update name, phone, address, and photo', style: TextStyle(color: context.textSecondaryColor)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () async {
                            if (user != null) {
                              final res = await Navigator.push(
                                context,
                                AppPageTransitions.slideRight(EditProfileScreen(user: user)),
                              );
                              if (res == true && mounted) {
                                profileProvider.fetchProfile();
                              }
                            }
                          },
                        ),
                        Divider(height: 1, color: context.borderColor),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.withAlpha(context.isDarkMode ? 40 : 30),
                            child: const Icon(Icons.lock_outline, color: Colors.orange),
                          ),
                          title: Text('Change Password', style: TextStyle(color: context.textPrimaryColor)),
                          subtitle: Text('Update your security password', style: TextStyle(color: context.textSecondaryColor)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            Navigator.push(
                              context,
                              AppPageTransitions.slideRight(const ChangePasswordScreen()),
                            );
                          },
                        ),
                        Divider(height: 1, color: context.borderColor),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple.withAlpha(context.isDarkMode ? 40 : 30),
                            child: const Icon(Icons.settings_outlined, color: Colors.purple),
                          ),
                          title: Text('App Settings', style: TextStyle(color: context.textPrimaryColor)),
                          subtitle: Text('Theme, notifications, and language', style: TextStyle(color: context.textSecondaryColor)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            Navigator.push(
                              context,
                              AppPageTransitions.slideRight(const SettingsScreen()),
                            );
                          },
                        ),
                        Divider(height: 1, color: context.borderColor),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.withAlpha(context.isDarkMode ? 40 : 30),
                            child: const Icon(Icons.help_outline, color: Colors.teal),
                          ),
                          title: Text('Help & Support', style: TextStyle(color: context.textPrimaryColor)),
                          subtitle: Text('FAQs, support contact, and feedback', style: TextStyle(color: context.textSecondaryColor)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            Navigator.push(
                              context,
                              AppPageTransitions.slideRight(const HelpSupportScreen()),
                            );
                          },
                        ),
                        Divider(height: 1, color: context.borderColor),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.withAlpha(context.isDarkMode ? 40 : 30),
                            child: const Icon(Icons.info_outline, color: Colors.indigo),
                          ),
                          title: Text('About MediShare', style: TextStyle(color: context.textPrimaryColor)),
                          subtitle: Text('Version, licenses, privacy policy', style: TextStyle(color: context.textSecondaryColor)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            Navigator.push(
                              context,
                              AppPageTransitions.slideRight(const AboutScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Logout Card
                  Card(
                    elevation: 0,
                    color: Colors.red.shade50.withAlpha(context.isDarkMode ? 40 : 255),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Logout Account',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      subtitle: Text(
                        'Sign out from this device safely',
                        style: TextStyle(color: context.isDarkMode ? Colors.white70 : Colors.red.shade900),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.red),
                      onTap: _showLogoutDialog,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Delete Account Action
                  Center(
                    child: TextButton.icon(
                      onPressed: _showDeleteAccountDialog,
                      icon: const Icon(Icons.delete_forever_outlined, size: 18, color: Colors.grey),
                      label: const Text(
                        'Delete Account',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel? user) {
    final role = user?.role ?? 'DONOR';
    final roleColor = role == 'ADMIN'
        ? Colors.purple
        : (role == 'DONOR' ? Colors.green : Colors.blue);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(context.isDarkMode ? 30 : 6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              MsImage(
                imageUrl: user?.profileImage,
                width: 72,
                height: 72,
                borderRadius: BorderRadius.circular(36),
                placeholderIcon: Icons.person,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user?.name ?? 'MediShare Member',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50.withAlpha(context.isDarkMode ? 40 : 255),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 12, color: Colors.teal),
                              SizedBox(width: 3),
                              Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'user@medishare.org',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: roleColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: roleColor.withAlpha(80)),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Member since Jul 2026',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (user?.phone != null && user!.phone!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: context.borderColor),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  user.phone!,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.textPrimaryColor),
                ),
                if (user.address != null && user.address!.isNotEmpty) ...[
                  const Spacer(),
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      user.address!,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.textPrimaryColor),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, ProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Activity & Impact Statistics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _buildStatCard(context, 'Equipment Listed', provider.equipmentCount.toString(), Icons.inventory_2_outlined, Colors.blue),
            _buildStatCard(context, 'Total Donations', provider.donationsCount.toString(), Icons.volunteer_activism_outlined, Colors.pink),
            _buildStatCard(context, 'Total Requests', provider.requestsCount.toString(), Icons.assignment_outlined, Colors.orange),
            _buildStatCard(context, 'Hospitals Connected', provider.hospitalsCount.toString(), Icons.local_hospital_outlined, Colors.teal),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: context.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withAlpha(25),
                  child: Icon(icon, size: 18, color: color),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: context.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}