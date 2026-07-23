import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

/// Premium Dynamic Theme-Aware MediShare Logo Widget
/// Perfectly visible in both Light Mode (Dark Text) and Dark Mode (Pure White Text).
class MsLogo extends StatelessWidget {
  final double height;
  final bool useIcon;
  final Color? color;

  const MsLogo({
    super.key,
    this.height = 38,
    this.useIcon = false,
    this.color,
  });

  const MsLogo.icon({
    super.key,
    this.height = 56,
    this.color,
  }) : useIcon = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: KeyedSubtree(
        key: ValueKey<bool>(isDark),
        child: useIcon ? _buildIconOnly(height) : _buildFullLogo(context, isDark),
      ),
    );
  }

  /// Icon-only variant
  Widget _buildIconOnly(double h) {
    return Image.asset(
      AppAssets.logoIcon,
      height: h,
      fit: BoxFit.contain,
      color: color,
      errorBuilder: (ctx, err, stack) => _MedicalCrossBadge(size: h, iconSize: h * 0.55),
    );
  }

  /// Full horizontal logo with dynamic theme-aware text
  Widget _buildFullLogo(BuildContext context, bool isDark) {
    final fontSize = (height * 0.6).clamp(18.0, 24.0);
    final iconHeight = (height * 0.85).clamp(28.0, 36.0);

    // Primary Text Color: White in Dark Mode, Navy Dark in Light Mode
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Medical Cross Icon (Asset with Vector Badge Fallback)
        Image.asset(
          AppAssets.logoIcon,
          height: iconHeight,
          fit: BoxFit.contain,
          errorBuilder: (ctx, err, stack) {
            return _MedicalCrossBadge(size: iconHeight, iconSize: iconHeight * 0.55);
          },
        ),
        const SizedBox(width: 8),

        // Dynamic High-Contrast MediShare Text
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Medi',
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Share',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Fallback Medical Cross Badge with Blue -> Cyan Gradient
class _MedicalCrossBadge extends StatelessWidget {
  final double size;
  final double iconSize;

  const _MedicalCrossBadge({
    required this.size,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(50),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Center(
        child: Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }
}
