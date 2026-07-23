import 'package:flutter/material.dart';

/// MediShare Brand Color Palette
/// Primary: #3B6CF8 (Blue — from logo cross)
/// Accent:  #2ECFB3 (Teal — from logo band)
/// Dark:    #141929 (Navy — logo background)
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────
  static const Color primary      = Color(0xFF3B6CF8);
  static const Color primaryDark  = Color(0xFF2855D8);
  static const Color primaryLight = Color(0xFF6B93FF);

  static const Color accent       = Color(0xFF2ECFB3);
  static const Color accentDark   = Color(0xFF22A892);
  static const Color accentLight  = Color(0xFF5FDCC8);

  static const Color dark         = Color(0xFF141929);
  static const Color dark2        = Color(0xFF1E2640);

  // ── Neutrals ───────────────────────────────────────────
  static const Color background   = Color(0xFFF8FAFF);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color surface2     = Color(0xFFEEF2FF);
  static const Color border       = Color(0xFFE2E8F7);

  // ── Text ───────────────────────────────────────────────
  static const Color textPrimary  = Color(0xFF1A2340);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint     = Color(0xFFA0AEC0);

  // ── Semantic ───────────────────────────────────────────
  static const Color success      = Color(0xFF22C55E);
  static const Color warning      = Color(0xFFF59E0B);
  static const Color error        = Color(0xFFEF4444);
  static const Color info         = Color(0xFF3B82F6);

  // ── Misc ───────────────────────────────────────────────
  static const Color white        = Colors.white;
  static const Color black        = Colors.black;
  static const Color transparent  = Colors.transparent;

  // ── Gradients ──────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0D1B4B), dark, Color(0xFF1A2A5E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [dark, Color(0xFF1E2A60), dark2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Extension on BuildContext for Material 3 Dynamic Theme Colors
extension ThemeContextExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;
  Color get surfaceBg => Theme.of(this).colorScheme.surface;
  Color get cardBg => isDarkMode ? const Color(0xFF242424) : AppColors.surface;
  Color get inputBg => isDarkMode ? const Color(0xFF2C2C2C) : AppColors.background;

  Color get textPrimaryColor => Theme.of(this).colorScheme.onSurface;
  Color get textSecondaryColor => isDarkMode ? Colors.white70 : AppColors.textSecondary;
  Color get textHintColor => isDarkMode ? Colors.white38 : AppColors.textHint;
  Color get borderColor => isDarkMode ? const Color(0xFF3A3A3A) : AppColors.border;
}