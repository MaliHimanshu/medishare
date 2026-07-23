import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themePrefKey = 'medishare_theme_mode';
  static const String _notifPrefKey = 'medishare_notif_enabled';
  static const String _langPrefKey = 'medishare_selected_lang';

  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';

  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  String get selectedLanguage => _selectedLanguage;

  ThemeProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themePrefKey);
      if (savedTheme != null) {
        if (savedTheme == 'light') {
          _themeMode = ThemeMode.light;
        } else if (savedTheme == 'dark') {
          _themeMode = ThemeMode.dark;
        } else {
          _themeMode = ThemeMode.system;
        }
      }

      _notificationsEnabled = prefs.getBool(_notifPrefKey) ?? true;
      _selectedLanguage = prefs.getString(_langPrefKey) ?? 'English';
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveThemeToPrefs(String themeStr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePrefKey, themeStr);
    } catch (_) {}
  }

  void setLight() {
    _themeMode = ThemeMode.light;
    _saveThemeToPrefs('light');
    notifyListeners();
  }

  void setDark() {
    _themeMode = ThemeMode.dark;
    _saveThemeToPrefs('dark');
    notifyListeners();
  }

  void setSystem() {
    _themeMode = ThemeMode.system;
    _saveThemeToPrefs('system');
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    if (mode == ThemeMode.light) {
      _saveThemeToPrefs('light');
    } else if (mode == ThemeMode.dark) {
      _saveThemeToPrefs('dark');
    } else {
      _saveThemeToPrefs('system');
    }
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notifPrefKey, value);
    } catch (_) {}
  }

  Future<void> setLanguage(String lang) async {
    _selectedLanguage = lang;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_langPrefKey, lang);
    } catch (_) {}
  }
}
