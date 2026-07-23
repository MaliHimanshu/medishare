import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/donation_model.dart';
import '../../providers/donation_provider.dart';
import '../../shared/widgets/ms_image.dart';
import 'edit_donation_dialog.dart';

class DonationDetailScreen extends StatefulWidget {
  final DonationModel donation;

  const DonationDetailScreen({
    super.key,
    required this.donation,
  });

  @override
  State<DonationDetailScreen> createState() => _DonationDetailScreenState();
}

class _DonationDetailScreenState extends State<DonationDetailScreen> {
  late DonationModel _currentDonation;

  @override
  void initState() {
    super.initState();
    _currentDonation = widget.donation;
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Colors.green;
      case 'COMPLETED':
        return Colors.blue;
      case 'REJECTED':
      case 'CANCELLED':
        return Colors.red;
      case 'PENDING':
      default:
        return Colors.orange;
    }
  }

  bool get _isPending => _currentDonation.status.toUpperCase() == 'PENDING';

  void _showStatusDialog() {
    final donationProvider = context.read<DonationProvider>();
    String selectedStatus = _currentDonation.status.toUpperCase();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Donation Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['PENDING', 'APPROVED', 'COMPLETED', 'REJECTED']
                        .map((st) {
                      final isSelected = selectedStatus == st;
                      final color = _getStatusColor(st);
                      return ChoiceChip(
                        label: Text(st),
                        selected: isSelected,
                        selectedColor: color.withAlpha(50),
                        labelStyle: TextStyle(
                          color: isSelected ? color : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => selectedStatus = st);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        navigator.pop();

                        final success = await donationProvider
                            .updateDonationStatus(_currentDonation.id, selectedStatus);

                        if (mounted) {
                          if (success) {
                            setState(() {
                              _currentDonation = donationProvider.donations
                                  .firstWhere((d) => d.id == _currentDonation.id,
                                      orElse: () => _currentDonation.copyWith(status: selectedStatus));
                            });
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Donation status updated!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(donationProvider.errorMessage.isNotEmpty
                                    ? donationProvider.errorMessage
                                    : 'Failed to update status.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Confirm Status Update',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openEditDialog() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => EditDonationDialog(donation: _currentDonation),
    );

    if (updated == true && mounted) {
      final provider = context.read<DonationProvider>();
      setState(() {
        _currentDonation = provider.donations.firstWhere(
          (d) => d.id == _currentDonation.id,
          orElse: () => _currentDonation,
        );
      });
    }
  }

  void _confirmDelete() {
    final donationProvider = context.read<DonationProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Delete Donation?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this donation record? This action cannot be undone.',
        ),
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

              final success =
                  await donationProvider.deleteDonation(_currentDonation.id);

              if (mounted) {
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Donation deleted successfully.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  navigator.pop(true);
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
    final equip = _currentDonation.equipment;
    final statusColor = _getStatusColor(_currentDonation.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Donation Details'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Banner Equipment Image using MsImage ───────
            Hero(
              tag: 'donation_image_${_currentDonation.id}',
              child: MsImage(
                imageUrl: equip?.image,
                width: double.infinity,
                height: 200,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 20),

            // ── Title & Status Chip ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equip?.name ?? 'Donated Medical Equipment',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Donation ID: #${_currentDonation.id}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withAlpha(100)),
                  ),
                  child: Text(
                    _currentDonation.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Details Grid Card ─────────────────────────────────
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
                      backgroundColor: Colors.purple.shade50,
                      child: const Icon(Icons.category, color: Colors.purple),
                    ),
                    title: const Text('Category'),
                    subtitle: Text(equip?.category ?? 'General Medical'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade50,
                      child: const Icon(Icons.numbers, color: Colors.orange),
                    ),
                    title: const Text('Quantity'),
                    subtitle: Text('${_currentDonation.quantity} units'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(Icons.person, color: Colors.blue),
                    ),
                    title: const Text('Donor'),
                    subtitle: Text(_currentDonation.donorName),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade50,
                      child: const Icon(Icons.local_hospital, color: Colors.red),
                    ),
                    title: const Text('Hospital / Location'),
                    subtitle: Text(_currentDonation.hospital),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade50,
                      child: const Icon(Icons.calendar_today,
                          color: Colors.indigo),
                    ),
                    title: const Text('Created Date'),
                    subtitle: Text(_currentDonation.createdAt.isNotEmpty
                        ? _currentDonation.createdAt.split('T').first
                        : 'Recently'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Notes Card ────────────────────────────────────────
            const Text(
              'Notes & Description',
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
                padding: const EdgeInsets.all(16),
                child: Text(
                  _currentDonation.notes.isNotEmpty
                      ? _currentDonation.notes
                      : 'No additional notes provided.',
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Actions Row ───────────────────────────────────────
            Row(
              children: [
                if (_isPending) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openEditDialog,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showStatusDialog,
                    icon: const Icon(Icons.sync_alt),
                    label: const Text('Status'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}