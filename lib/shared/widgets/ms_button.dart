import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Reusable branded button with variants and loading state
class MsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final double? height;
  final double? borderRadius;

  const MsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.height,
    this.borderRadius,
  });

  const MsButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height,
    this.borderRadius,
  })  : isOutlined = true,
        backgroundColor = null,
        foregroundColor = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final bool disabled = isLoading || onPressed == null;

    final Widget child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    final radius = BorderRadius.circular(borderRadius ?? 14);

    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: height ?? 56,
        child: OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor ?? AppColors.primary,
            side: BorderSide(
              color: disabled ? AppColors.border : (foregroundColor ?? AppColors.primary),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: height ?? 56,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: foregroundColor ?? AppColors.white,
          disabledBackgroundColor: AppColors.primary.withAlpha(120),
          shape: RoundedRectangleBorder(borderRadius: radius),
          elevation: 0,
        ),
        child: child,
      ),
    );
  }
}
