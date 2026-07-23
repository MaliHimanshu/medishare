import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_translations.dart';
import '../../providers/theme_provider.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final lang = themeProvider.selectedLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.getText(lang, 'settings')),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Mode Section Header
            Text(
              'Appearance & Theme',
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
                    leading: const Icon(Icons.light_mode_outlined, color: Colors.orange),
                    title: Text(
                      AppTranslations.getText(lang, 'light_mode'),
                      style: TextStyle(color: context.textPrimaryColor),
                    ),
                    trailing: Icon(
                      themeProvider.themeMode == ThemeMode.light
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: themeProvider.themeMode == ThemeMode.light
                          ? AppColors.primary
                          : Colors.grey,
                    ),
                    onTap: () {
                      themeProvider.setThemeMode(ThemeMode.light);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Switched to Light Mode')),
                      );
                    },
                  ),
                  Divider(height: 1, color: context.borderColor),
                  ListTile(
                    leading: const Icon(Icons.dark_mode_outlined, color: Colors.indigo),
                    title: Text(
                      AppTranslations.getText(lang, 'dark_mode'),
                      style: TextStyle(color: context.textPrimaryColor),
                    ),
                    trailing: Icon(
                      themeProvider.themeMode == ThemeMode.dark
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: themeProvider.themeMode == ThemeMode.dark
                          ? AppColors.primary
                          : Colors.grey,
                    ),
                    onTap: () {
                      themeProvider.setThemeMode(ThemeMode.dark);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Switched to Dark Mode')),
                      );
                    },
                  ),
                  Divider(height: 1, color: context.borderColor),
                  ListTile(
                    leading: const Icon(Icons.brightness_auto, color: AppColors.primary),
                    title: Text(
                      AppTranslations.getText(lang, 'system_mode'),
                      style: TextStyle(color: context.textPrimaryColor),
                    ),
                    trailing: Icon(
                      themeProvider.themeMode == ThemeMode.system
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: themeProvider.themeMode == ThemeMode.system
                          ? AppColors.primary
                          : Colors.grey,
                    ),
                    onTap: () {
                      themeProvider.setThemeMode(ThemeMode.system);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Switched to System Theme')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notifications Section Header
            Text(
              'Notifications & Alerts',
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
              child: SwitchListTile(
                secondary: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(Icons.notifications_active_outlined, color: Colors.blue),
                ),
                title: Text(
                  AppTranslations.getText(lang, 'push_notifications'),
                  style: TextStyle(color: context.textPrimaryColor),
                ),
                subtitle: Text(
                  'Receive alerts for donations, requests, and updates',
                  style: TextStyle(color: context.textSecondaryColor),
                ),
                value: themeProvider.notificationsEnabled,
                onChanged: (val) {
                  themeProvider.toggleNotifications(val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(val ? 'Notifications Enabled' : 'Notifications Disabled'),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Language Selector Section Header
            Text(
              AppTranslations.getText(lang, 'app_language'),
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
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade50,
                  child: const Icon(Icons.language, color: Colors.teal),
                ),
                title: Text(
                  AppTranslations.getText(lang, 'app_language'),
                  style: TextStyle(color: context.textPrimaryColor),
                ),
                subtitle: Text(
                  themeProvider.selectedLanguage,
                  style: TextStyle(color: context.textSecondaryColor),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showLanguageDialog(context, themeProvider);
                },
              ),
            ),

            const SizedBox(height: 24),

            // Information & Legal Section Header
            Text(
              'Information & Legal',
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
                    leading: const Icon(Icons.help_outline, color: AppColors.primary),
                    title: Text(
                      AppTranslations.getText(lang, 'help_support'),
                      style: TextStyle(color: context.textPrimaryColor),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                      );
                    },
                  ),
                  Divider(height: 1, color: context.borderColor),
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: Colors.purple),
                    title: Text(
                      AppTranslations.getText(lang, 'about'),
                      style: TextStyle(color: context.textPrimaryColor),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    },
                  ),
                  Divider(height: 1, color: context.borderColor),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: Colors.green),
                    title: Text('Privacy Policy', style: TextStyle(color: context.textPrimaryColor)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                      );
                    },
                  ),
                  Divider(height: 1, color: context.borderColor),
                  ListTile(
                    leading: const Icon(Icons.description_outlined, color: Colors.amber),
                    title: Text('Terms & Conditions', style: TextStyle(color: context.textPrimaryColor)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, ThemeProvider themeProvider) {
    final languages = ['English', 'Hindi (हिंदी)', 'Gujarati (ગુજરાતી)', 'Spanish (Español)'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Select App Language',
          style: TextStyle(color: context.textPrimaryColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            final isSelected = themeProvider.selectedLanguage == lang;
            return ListTile(
              title: Text(lang, style: TextStyle(color: context.textPrimaryColor)),
              trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                themeProvider.setLanguage(lang);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Language changed to $lang')),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}