import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MSDialogs {
  MSDialogs._();

  /// Standard Confirmation Dialog
  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Color confirmColor = AppColors.primary,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: TextStyle(color: context.textPrimaryColor)),
        content: Text(message, style: TextStyle(color: context.textSecondaryColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  /// Delete Confirmation Dialog
  static Future<bool?> showDelete({
    required BuildContext context,
    required String itemName,
  }) {
    return showConfirm(
      context: context,
      title: 'Delete Item',
      message: 'Are you sure you want to delete "$itemName"? This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: AppColors.error,
    );
  }

  /// Logout Dialog
  static Future<bool?> showLogout(BuildContext context) {
    return showConfirm(
      context: context,
      title: 'Logout Account',
      message: 'Are you sure you want to log out of your MediShare account?',
      confirmLabel: 'Logout',
      confirmColor: AppColors.error,
    );
  }

  /// Success Message Dialog
  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 28),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: context.textPrimaryColor)),
          ],
        ),
        content: Text(message, style: TextStyle(color: context.textSecondaryColor)),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Error Message Dialog
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 28),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: context.textPrimaryColor)),
          ],
        ),
        content: Text(message, style: TextStyle(color: context.textSecondaryColor)),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
