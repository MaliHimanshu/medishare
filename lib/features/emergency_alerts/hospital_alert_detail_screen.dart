// Hospital Emergency Alert Detail & NGO Response Screen
// File: lib/features/emergency_alerts/hospital_alert_detail_screen.dart
//
// Displays live progress of NGO contributions, total available equipment,
// individual NGO offers, and emergency alert lifecycle management.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/emergency_alert_provider.dart';
import '../../shared/widgets/ms_button.dart';

class HospitalAlertDetailScreen extends StatefulWidget {
  final String alertId;

  const HospitalAlertDetailScreen({super.key, required this.alertId});

  @override
  State<HospitalAlertDetailScreen> createState() => _HospitalAlertDetailScreenState();
}

class _HospitalAlertDetailScreenState extends State<HospitalAlertDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmergencyAlertProvider>().fetchAlertDetails(widget.alertId);
    });
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFDC2626);
      case 'HIGH':
        return const Color(0xFFEA580C);
      case 'NORMAL':
      default:
        return const Color(0xFF2563EB);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.blue;
      case 'PARTIALLY_FULFILLED':
        return Colors.orange;
      case 'FULFILLED':
        return Colors.green;
      case 'CANCELLED':
      case 'EXPIRED':
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleUpdateStatus(String newStatus, String actionName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$actionName Emergency Alert?'),
        content: Text(
          'Are you sure you want to mark this emergency alert as $newStatus? NGOs will no longer be able to submit new offers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Back', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'CANCELLED' ? Colors.red : Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(actionName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final prov = context.read<EmergencyAlertProvider>();
    final success = await prov.updateAlertStatus(widget.alertId, newStatus);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Emergency alert marked as $newStatus'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.errorMessage ?? 'Failed to update alert status'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<EmergencyAlertProvider>();
    final alert = prov.selectedAlert;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Emergency Alert Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => prov.fetchAlertDetails(widget.alertId),
          ),
        ],
      ),
      body: prov.isLoading && alert == null
          ? const Center(child: CircularProgressIndicator())
          : alert == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(prov.errorMessage ?? 'Alert not found'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => prov.fetchAlertDetails(widget.alertId),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => prov.fetchAlertDetails(widget.alertId),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Main Card ──────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getPriorityColor(alert.priority).withAlpha(100),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _getPriorityColor(alert.priority).withAlpha(20),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badges row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(alert.priority).withAlpha(25),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.crisis_alert_rounded,
                                          size: 14,
                                          color: _getPriorityColor(alert.priority),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${alert.priority} PRIORITY',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _getPriorityColor(alert.priority),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(alert.status).withAlpha(25),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      alert.status.replaceAll('_', ' '),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(alert.status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              Text(
                                alert.equipmentName,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                              if (alert.equipmentCategory != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Category: ${alert.equipmentCategory}',
                                  style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
                                ),
                              ],
                              const SizedBox(height: 16),

                              // Progress Counter & Bar
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: context.isDarkMode ? Colors.black26 : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Fulfillment Progress',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: context.textPrimaryColor,
                                          ),
                                        ),
                                        Text(
                                          '${alert.totalAvailable} / ${alert.quantityRequired} units',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: alert.totalAvailable >= alert.quantityRequired
                                                ? Colors.green
                                                : AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: alert.fulfillmentPercentage,
                                        minHeight: 10,
                                        backgroundColor: Colors.grey.shade300,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          alert.totalAvailable >= alert.quantityRequired
                                              ? Colors.green
                                              : (alert.totalAvailable > 0 ? Colors.orange : Colors.grey),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${(alert.fulfillmentPercentage * 100).toStringAsFixed(0)}% fulfilled from ${alert.responses.length} NGO offers',
                                      style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                                    ),
                                  ],
                                ),
                              ),

                              if (alert.description != null) ...[
                                const SizedBox(height: 14),
                                Text(
                                  'Description:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textSecondaryColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  alert.description!,
                                  style: TextStyle(fontSize: 14, height: 1.4, color: context.textPrimaryColor),
                                ),
                              ],

                              if (alert.address != null) ...[
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        alert.address!,
                                        style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── NGO Responses Header ────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'NGO Responses (${alert.responses.length})',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            if (alert.responses.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '+${alert.totalAvailable} Units Offered',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Responses List
                        if (alert.responses.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.hourglass_empty_rounded, size: 36, color: Colors.grey),
                                const SizedBox(height: 10),
                                const Text(
                                  'Waiting for NGO responses...',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Eligible partner NGOs have been alerted via push and in-app notifications.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: alert.responses.length,
                            separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final resp = alert.responses[index];
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: context.cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.withAlpha(30)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            resp.ngo?.displayName ?? 'Partner NGO',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: context.textPrimaryColor,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withAlpha(25),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '+${resp.quantityAvailable} units',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (resp.ngo?.phone != null) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.phone_outlined, size: 14, color: AppColors.primary),
                                          const SizedBox(width: 6),
                                          Text(
                                            resp.ngo!.phone!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (resp.message != null && resp.message!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: context.isDarkMode ? Colors.black12 : Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '"${resp.message!}"',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                            color: context.textSecondaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 32),

                        // Action Buttons (Close / Cancel)
                        if (alert.isActive) ...[
                          if (alert.totalAvailable >= alert.quantityRequired) ...[
                            MsButton(
                              label: 'MARK AS FULFILLED ✅',
                              onPressed: () => _handleUpdateStatus('FULFILLED', 'Close & Fulfill'),
                              backgroundColor: Colors.green,
                              icon: Icons.check_circle_outline_rounded,
                            ),
                            const SizedBox(height: 12),
                          ],
                          OutlinedButton.icon(
                            onPressed: () => _handleUpdateStatus('CANCELLED', 'Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.cancel_outlined, size: 20),
                            label: const Text('CANCEL EMERGENCY ALERT', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }
}
