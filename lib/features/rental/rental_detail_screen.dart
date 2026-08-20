import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/rental_model.dart';
import '../tracking/live_tracking_screen.dart';
import '../../providers/rental_provider.dart';
import '../../shared/widgets/ms_image.dart';
import 'razorpay_checkout_sheet.dart';

class RentalDetailScreen extends StatefulWidget {
  final RentalModel rental;

  const RentalDetailScreen({
    super.key,
    required this.rental,
  });

  @override
  State<RentalDetailScreen> createState() => _RentalDetailScreenState();
}

class _RentalDetailScreenState extends State<RentalDetailScreen> {
  late RentalModel _currentRental;

  @override
  void initState() {
    super.initState();
    _currentRental = widget.rental;
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Colors.blue;
      case 'ACTIVE':
        return Colors.green;
      case 'RETURNED':
        return Colors.teal;
      case 'REJECTED':
      case 'CANCELLED':
        return Colors.red;
      case 'PENDING':
      default:
        return Colors.orange;
    }
  }

  void _showStatusDialog() {
    final rentalProvider = context.read<RentalProvider>();
    String selectedStatus = _currentRental.status.toUpperCase();

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
                    'Update Rental Status',
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
                    children: [
                      'PENDING',
                      'APPROVED',
                      'ACTIVE',
                      'RETURNED',
                      'CANCELLED',
                      'REJECTED',
                    ].map((st) {
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
                        backgroundColor: Colors.orange.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        navigator.pop();

                        final success = await rentalProvider
                            .updateRentalStatus(_currentRental.id, selectedStatus);

                        if (mounted) {
                          if (success) {
                            setState(() {
                              _currentRental = _currentRental.copyWith(status: selectedStatus);
                            });
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Rental status updated!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(rentalProvider.errorMessage.isNotEmpty
                                    ? rentalProvider.errorMessage
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

  void _confirmDelete() {
    final rentalProvider = context.read<RentalProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Delete Rental?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this rental record? This action cannot be undone.',
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
                  await rentalProvider.deleteRental(_currentRental.id);

              if (mounted) {
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Rental deleted successfully.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  navigator.pop(true);
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(rentalProvider.errorMessage.isNotEmpty
                          ? rentalProvider.errorMessage
                          : 'Failed to delete rental.'),
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
    final equip = _currentRental.equipment;
    final statusColor = _getStatusColor(_currentRental.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rental Details'),
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
            // Equipment Image
            MsImage(
              imageUrl: equip?.image,
              width: double.infinity,
              height: 180,
              borderRadius: BorderRadius.circular(20),
              placeholderIcon: Icons.medical_services_outlined,
            ),

            const SizedBox(height: 20),

            // Title & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equip?.name ?? 'Rented Equipment',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Booking ID: #${_currentRental.id}',
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
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withAlpha(100)),
                  ),
                  child: Text(
                    _currentRental.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Financial & Rental Details Card
            Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Rental Financial Summary",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 14),
                    _buildRow("Duration", "${_currentRental.numberOfDays} day(s)"),
                    const SizedBox(height: 8),
                    _buildRow("Rental Amount", "₹${_currentRental.rentalAmount.toStringAsFixed(0)}"),
                    const SizedBox(height: 8),
                    _buildRow("Security Deposit (Refundable)", "₹${_currentRental.securityDeposit.toStringAsFixed(0)}"),
                    const Divider(height: 20),
                    _buildRow(
                      "Total Amount",
                      "₹${_currentRental.totalAmount.toStringAsFixed(0)}",
                      isBold: true,
                      color: Colors.orange.shade800,
                    ),
                    const SizedBox(height: 8),
                    _buildRow("Payment Status", _currentRental.paymentStatus.toUpperCase(),
                        color: _currentRental.paymentStatus.toUpperCase() == 'PAID'
                            ? Colors.green
                            : _currentRental.paymentStatus.toUpperCase() == 'FAILED'
                                ? Colors.red
                                : Colors.orange),
                    if (_currentRental.razorpayOrderId != null &&
                        _currentRental.razorpayOrderId!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildRow("Razorpay Order ID", _currentRental.razorpayOrderId!),
                    ],
                    if (_currentRental.razorpayPaymentId != null &&
                        _currentRental.razorpayPaymentId!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildRow("Razorpay Payment ID", _currentRental.razorpayPaymentId!),
                    ],
                  ],
                ),
              ),
            ),

            if (_currentRental.paymentStatus.toUpperCase() != 'PAID') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C2340),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.bolt, color: Colors.blueAccent),
                  label: Text(
                    "Pay ₹${_currentRental.totalAmount.toStringAsFixed(0)} via Razorpay",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: () async {
                    final prov = context.read<RentalProvider>();
                    final res = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => RazorpayCheckoutSheet(rental: _currentRental),
                    );

                    if (res == true && mounted) {
                      await prov.fetchRentals();
                      if (mounted) {
                        setState(() {
                          _currentRental = prov.rentals.firstWhere(
                            (r) => r.id == _currentRental.id,
                            orElse: () => _currentRental.copyWith(
                              paymentStatus: 'PAID',
                              status: 'APPROVED',
                            ),
                          );
                        });
                      }
                    }
                  },
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Dates & Renter Information Card
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
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(Icons.person, color: Colors.blue),
                    ),
                    title: const Text('Renter'),
                    subtitle: Text(_currentRental.renterName),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade50,
                      child: const Icon(Icons.date_range, color: Colors.orange),
                    ),
                    title: const Text('Rental Period'),
                    subtitle: Text(
                      '${_currentRental.startDate.split('T').first}  →  ${_currentRental.endDate.split('T').first}',
                    ),
                  ),
                ],
              ),
            ),

            if (_currentRental.status.toUpperCase() == 'ACTIVE') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text(
                    'Track Live Location',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LiveTrackingScreen(rental: _currentRental),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Actions Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showStatusDialog,
                    icon: const Icon(Icons.sync_alt),
                    label: const Text('Update Status'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
