import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  IconData _getIconForModule(String module, String type) {
    if (type.contains('APPROVAL') || type.contains('APPROVED')) {
      return Icons.check_circle_outline;
    }
    if (type.contains('REJECT')) {
      return Icons.cancel_outlined;
    }

    switch (module.toLowerCase()) {
      case 'donations':
      case 'donation':
        return Icons.volunteer_activism_outlined;
      case 'requests':
      case 'request':
        return Icons.assignment_outlined;
      case 'hospitals':
      case 'hospital':
        return Icons.local_hospital_outlined;
      case 'equipment':
        return Icons.medical_services_outlined;
      case 'ai':
        return Icons.smart_toy_outlined;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _getColorForModule(String module, String type) {
    if (type.contains('APPROVAL') || type.contains('APPROVED')) {
      return Colors.green;
    }
    if (type.contains('REJECT')) {
      return Colors.red;
    }

    switch (module.toLowerCase()) {
      case 'donations':
      case 'donation':
        return Colors.pink;
      case 'requests':
      case 'request':
        return Colors.orange;
      case 'hospitals':
      case 'hospital':
        return Colors.teal;
      case 'equipment':
        return Colors.blue;
      case 'ai':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  void _confirmDelete(BuildContext context) {
    final provider = context.read<NotificationProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              Navigator.pop(ctx);

              final success = await provider.deleteNotification(notification.id);

              if (context.mounted) {
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Notification deleted.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  navigator.pop();
                } else {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete notification.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconData = _getIconForModule(notification.module, notification.type);
    final themeColor = _getColorForModule(notification.module, notification.type);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notification Details'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Banner
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: themeColor.withAlpha(25),
                child: Icon(iconData, size: 48, color: themeColor),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Center(
              child: Text(
                notification.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Meta Info Card
            Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: themeColor.withAlpha(20),
                      child: Icon(Icons.category, color: themeColor),
                    ),
                    title: const Text('Related Module'),
                    subtitle: Text(notification.module),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade50,
                      child: const Icon(Icons.calendar_today, color: Colors.indigo),
                    ),
                    title: const Text('Date & Time'),
                    subtitle: Text(
                      notification.createdAt.isNotEmpty
                          ? notification.createdAt.replaceAll('T', ' • ').split('.').first
                          : 'Recently',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notification.isRead ? Colors.grey.shade100 : AppColors.primary.withAlpha(20),
                      child: Icon(
                        notification.isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                        color: notification.isRead ? Colors.grey : AppColors.primary,
                      ),
                    ),
                    title: const Text('Status'),
                    subtitle: Text(
                      notification.isRead ? 'Read' : 'Unread',
                      style: TextStyle(
                        color: notification.isRead ? Colors.grey : AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Message Box
            const Text(
              'Notification Message',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  notification.message,
                  style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.textPrimary),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Back button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Notifications'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
