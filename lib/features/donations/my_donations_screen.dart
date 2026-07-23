import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_page_transitions.dart';
import '../../models/donation_model.dart';
import '../../providers/donation_provider.dart';
import '../../shared/widgets/ms_skeleton.dart';
import '../../shared/widgets/ms_image.dart';
import '../../shared/widgets/ms_animations.dart';
import '../../shared/widgets/ms_empty_state.dart';
import '../../shared/widgets/ms_error_widget.dart';
import 'create_donation_screen.dart';
import 'donation_detail_screen.dart';
import 'edit_donation_dialog.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DonationProvider>().fetchDonations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<DonationProvider>().fetchDonations();
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return AppColors.success;
      case 'COMPLETED':
        return AppColors.info;
      case 'REJECTED':
      case 'CANCELLED':
        return AppColors.error;
      case 'PENDING':
      default:
        return AppColors.warning;
    }
  }

  void _showStatusDialog(DonationModel donation) {
    final donationProvider = context.read<DonationProvider>();
    String selectedStatus = donation.status.toUpperCase();

    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update Donation Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      dropdownColor: context.cardBg,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'PENDING', child: Text('PENDING')),
                        DropdownMenuItem(
                            value: 'APPROVED', child: Text('APPROVED')),
                        DropdownMenuItem(
                            value: 'COMPLETED', child: Text('COMPLETED')),
                        DropdownMenuItem(
                            value: 'REJECTED', child: Text('REJECTED')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedStatus = val);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(ctx);

                          final success = await donationProvider
                              .updateDonationStatus(donation.id, selectedStatus);

                          if (mounted) {
                            if (success) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Donation status updated!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(donationProvider
                                          .errorMessage.isNotEmpty
                                      ? donationProvider.errorMessage
                                      : 'Failed to update status.'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Save Status'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openEditDialog(DonationModel donation) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => EditDonationDialog(donation: donation),
    );

    if (updated == true && mounted) {
      context.read<DonationProvider>().fetchDonations();
    }
  }

  void _confirmDelete(DonationModel donation) {
    final donationProvider = context.read<DonationProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Donation'),
        content: Text(
            'Are you sure you want to delete donation "${donation.equipment?.name ?? 'Item'}"?'),
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

              final success =
                  await donationProvider.deleteDonation(donation.id);

              if (mounted) {
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Donation deleted successfully.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(donationProvider.errorMessage.isNotEmpty
                          ? donationProvider.errorMessage
                          : 'Failed to delete donation.'),
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
    final donationProvider = context.watch<DonationProvider>();
    final filtered = donationProvider.filteredDonations;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('My Donations'),
        centerTitle: true,
        backgroundColor: context.surfaceBg,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: donationProvider.fetchDonations,
          ),
        ],
      ),
      floatingActionButton: AnimatedFAB(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            AppPageTransitions.slideUp(const CreateDonationScreen()),
          );
          if (res == true && mounted) {
            donationProvider.fetchDonations();
          }
        },
        icon: Icons.add,
        label: 'Donate Equipment',
      ),
      body: Column(
        children: [
          // ── Search & Filter Bar ────────────────────────────────────
          Container(
            color: context.surfaceBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  onChanged: donationProvider.setSearchQuery,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    hintText: 'Search equipment, category, donor, hospital...',
                    hintStyle: TextStyle(color: context.textHintColor),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              donationProvider.setSearchQuery('');
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

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'All',
                      'Pending',
                      'Approved',
                      'Completed',
                      'Rejected',
                    ].map((st) {
                      final isSelected = donationProvider.selectedStatus == st;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            st == 'All' ? 'All Status' : st,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : context.textPrimaryColor,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary.withAlpha(35),
                          onSelected: (val) {
                            donationProvider.setStatusFilter(st);
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
              child: _buildContent(donationProvider, filtered),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      DonationProvider donationProvider, List<DonationModel> filtered) {
    if (donationProvider.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, index) => const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: MsSkeleton(height: 140),
        ),
      );
    }

    if (donationProvider.errorMessage.isNotEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: MSErrorWidget(
          title: 'Failed to load donations',
          message: donationProvider.errorMessage,
          onRetry: donationProvider.fetchDonations,
        ),
      );
    }

    if (filtered.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: MSEmptyState(
            icon: Icons.volunteer_activism_outlined,
            title: 'No donations yet',
            subtitle: 'Tap Donate Equipment to create your first donation.',
            actionLabel: 'Donate Equipment',
            onAction: () async {
              final res = await Navigator.push(
                context,
                AppPageTransitions.slideUp(const CreateDonationScreen()),
              );
              if (res == true && mounted) {
                donationProvider.fetchDonations();
              }
            },
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final equip = item.equipment;
        final statusColor = _getStatusColor(item.status);
        final isPending = item.status.toUpperCase() == 'PENDING';

        return AnimatedListItem(
          index: index,
          child: Card(
            margin: const EdgeInsets.only(bottom: 14),
            elevation: 0,
            color: context.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.borderColor),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  AppPageTransitions.slideRight(
                    DonationDetailScreen(donation: item),
                  ),
                );
              },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Equipment Image with Hero transition & MsImage
                      Hero(
                        tag: 'donation_image_${item.id}',
                        child: MsImage(
                          imageUrl: equip?.image,
                          width: 56,
                          height: 56,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              equip?.name ?? 'Medical Equipment',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Category: ${equip?.category ?? 'Medical'} • Qty: ${item.quantity}',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Donor: ${item.donorName} • Hospital: ${item.hospital}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Divider(height: 1, color: context.borderColor),
                  const SizedBox(height: 10),

                  // Bottom Row: Date, Status Badge, Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 14, color: context.textSecondaryColor),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.createdAt.isNotEmpty
                                    ? item.createdAt
                                        .replaceAll('T', ' ')
                                        .split('.')
                                        .first
                                    : 'Recent',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.textSecondaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Status Badge
                          GestureDetector(
                            onTap: () => _showStatusDialog(item),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: statusColor.withAlpha(80)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 3,
                                    backgroundColor: statusColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.status.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Edit Action (if Pending)
                          if (isPending)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 16, color: AppColors.primary),
                              tooltip: 'Edit Donation',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              onPressed: () => _openEditDialog(item),
                            ),

                          // Delete Action
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 16, color: Colors.red),
                            tooltip: 'Delete Donation',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            onPressed: () => _confirmDelete(item),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    );
  }
}