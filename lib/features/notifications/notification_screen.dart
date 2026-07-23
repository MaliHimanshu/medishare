import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../shared/widgets/ms_skeleton.dart';
import '../../shared/widgets/ms_animations.dart';
import '../../core/theme/app_page_transitions.dart';
import 'notification_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<NotificationProvider>().fetchNotifications();
  }

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
        return Icons.notifications_none_outlined;
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
        return Colors.redAccent;
      case 'equipment':
        return AppColors.primary;
      case 'ai':
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }

  void _confirmDelete(NotificationModel notification) {
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
              Navigator.pop(ctx);

              final success = await provider.deleteNotification(notification.id);

              if (mounted) {
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Notification deleted.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
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
    final notificationProvider = context.watch<NotificationProvider>();
    final filtered = notificationProvider.filteredNotifications;
    final unreadCount = notificationProvider.unreadCount;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Notifications'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        backgroundColor: context.surfaceBg,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: notificationProvider.fetchNotifications,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Module Filter Header
          Container(
            color: context.surfaceBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search Input Field
                TextField(
                  controller: _searchController,
                  onChanged: notificationProvider.setSearchQuery,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    hintText: 'Search title, message, or module...',
                    hintStyle: TextStyle(color: context.textHintColor),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              notificationProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: context.inputBg,
                  ),
                ),

                const SizedBox(height: 10),

                // Module Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'All',
                      'Equipment',
                      'Donations',
                      'Requests',
                      'Hospitals',
                      'AI',
                    ].map((mod) {
                      final isSelected = notificationProvider.selectedFilter == mod;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            mod == 'All' ? 'All Modules' : mod,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : context.textPrimaryColor,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary.withAlpha(35),
                          onSelected: (val) {
                            notificationProvider.setFilter(mod);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: _buildContent(notificationProvider, filtered),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      NotificationProvider notificationProvider, List<NotificationModel> filtered) {
    if (notificationProvider.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: MsSkeleton(height: 90),
        ),
      );
    }

    if (notificationProvider.errorMessage.isNotEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(32),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.error_outline, size: 60, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                notificationProvider.errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: context.textSecondaryColor),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: notificationProvider.fetchNotifications,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(32),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withAlpha(20),
                child: const Icon(
                  Icons.notifications_none_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Notifications Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All caught up! New updates regarding equipment, donations, and requests will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final iconData = _getIconForModule(item.module, item.type);
        final themeColor = _getColorForModule(item.module, item.type);

        return AnimatedListItem(
          index: index,
          child: Dismissible(
          key: Key('notif_${item.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
          ),
          confirmDismiss: (direction) async {
            _confirmDelete(item);
            return false;
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: item.isRead ? 0 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: item.isRead ? context.borderColor : themeColor.withAlpha(100),
                width: item.isRead ? 1 : 1.5,
              ),
            ),
            color: item.isRead ? context.cardBg : themeColor.withAlpha(25),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (!item.isRead) {
                  notificationProvider.markAsRead(item.id);
                }
                Navigator.push(
                  context,
                  AppPageTransitions.slideUp(
                    NotificationDetailScreen(notification: item),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification Icon Circle
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: themeColor.withAlpha(25),
                      child: Icon(iconData, color: themeColor, size: 22),
                    ),
                    const SizedBox(width: 12),

                    // Title & Message Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                    fontSize: 15,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                              ),
                              if (!item.isRead)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'NEW',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondaryColor,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.createdAt.isNotEmpty
                                    ? item.createdAt.replaceAll('T', ' ').split('.').first
                                    : 'Recent',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: themeColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.module.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: themeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ), // end InkWell
          ), // end Card
          ), // end Dismissible
        ); // end AnimatedListItem
      },
    );
  }
}