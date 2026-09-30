// NGO Emergency Equipment Request Detail & Response Screen
// File: lib/features/emergency_alerts/ngo_emergency_detail_screen.dart
//
// Allows verified NGOs to review critical hospital equipment needs
// and commit available inventory units.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/emergency_alert_provider.dart';
import '../../shared/widgets/ms_button.dart';
import '../../shared/widgets/ms_text_field.dart';

class NgoEmergencyDetailScreen extends StatefulWidget {
  final String alertId;

  const NgoEmergencyDetailScreen({super.key, required this.alertId});

  @override
  State<NgoEmergencyDetailScreen> createState() =>
      _NgoEmergencyDetailScreenState();
}

class _NgoEmergencyDetailScreenState extends State<NgoEmergencyDetailScreen> {
  final _quantityCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetails();
    });
  }

  Future<void> _loadDetails() async {
    final prov = context.read<EmergencyAlertProvider>();
    final alert = await prov.fetchAlertDetails(widget.alertId);
    if (alert != null && alert.myResponse != null) {
      _quantityCtrl.text = alert.myResponse!.quantityAvailable.toString();
      _messageCtrl.text = alert.myResponse!.message ?? '';
    }
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
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

  Future<void> _handleRespond() async {
    final qty = int.tryParse(_quantityCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid available quantity (> 0)'),
        ),
      );
      return;
    }

    final prov = context.read<EmergencyAlertProvider>();
    final success = await prov.respondToAlert(
      alertId: widget.alertId,
      quantityAvailable: qty,
      message: _messageCtrl.text.trim().isEmpty
          ? null
          : _messageCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Response submitted! Hospital notified of $qty units offered.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isEditing = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.errorMessage ?? 'Failed to submit response'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleUpdateResponse() async {
    final qty = int.tryParse(_quantityCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid available quantity (> 0)'),
        ),
      );
      return;
    }

    final prov = context.read<EmergencyAlertProvider>();
    final success = await prov.updateResponse(
      alertId: widget.alertId,
      quantityAvailable: qty,
      message: _messageCtrl.text.trim().isEmpty
          ? null
          : _messageCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer updated successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isEditing = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.errorMessage ?? 'Failed to update offer'),
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
          '🚨 Emergency Equipment Request',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: prov.isLoading && alert == null
          ? const Center(child: CircularProgressIndicator())
          : alert == null
          ? Center(child: Text(prov.errorMessage ?? 'Alert not found'))
          : RefreshIndicator(
              onRefresh: () => prov.fetchAlertDetails(widget.alertId),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hospital & Urgency Banner
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getPriorityColor(
                            alert.priority,
                          ).withAlpha(100),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getPriorityColor(
                              alert.priority,
                            ).withAlpha(20),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(
                                    alert.priority,
                                  ).withAlpha(25),
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
                                        color: _getPriorityColor(
                                          alert.priority,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (alert.hospital != null)
                                Text(
                                  'Hospital Request',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.textSecondaryColor,
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
                          const SizedBox(height: 8),

                          // Quantity Requested Chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(
                                alert.priority,
                              ).withAlpha(15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.emergency_rounded,
                                  size: 18,
                                  color: Color(0xFFDC2626),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Required: ${alert.quantityRequired} units',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 14),

                          // Hospital Details
                          if (alert.hospital != null) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.local_hospital_rounded,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        alert.hospital!.displayName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: context.textPrimaryColor,
                                        ),
                                      ),
                                      if (alert.address != null ||
                                          alert.hospital!.address != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          alert.address ??
                                              alert.hospital!.address!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.textSecondaryColor,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                          ],

                          if (alert.description != null) ...[
                            Text(
                              'Urgency Note:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: context.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert.description!,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: context.textPrimaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Response Section ────────────────────────
                    Text(
                      'Your NGO Contribution',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // If already responded and not editing
                    if (alert.myResponse != null && !_isEditing) ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(20),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.green.withAlpha(80)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Response Submitted ✅',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.green,
                                  ),
                                  onPressed: () {
                                    setState(() => _isEditing = true);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your NGO committed ${alert.myResponse!.quantityAvailable} units for this emergency.',
                              style: TextStyle(
                                fontSize: 14,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            if (alert.myResponse!.message != null &&
                                alert.myResponse!.message!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                '"${alert.myResponse!.message!}"',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else ...[
                      // Response Form
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.withAlpha(40)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available Quantity You Can Provide *',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            MsTextField(
                              label: 'Units available',
                              hint: 'e.g. 10',
                              controller: _quantityCtrl,
                              keyboardType: TextInputType.number,
                              prefixIcon: Icons.inventory_2_outlined,
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'Dispatch Note / Message',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            MsTextField(
                              label: 'Notes for hospital',
                              hint:
                                  'e.g. We have 10 cylinders ready for immediate pickup or delivery.',
                              controller: _messageCtrl,
                              maxLines: 3,
                              prefixIcon: Icons.chat_bubble_outline_rounded,
                            ),
                            const SizedBox(height: 20),

                            Row(
                              children: [
                                if (_isEditing)
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          setState(() => _isEditing = false),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(
                                          double.infinity,
                                          48,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                if (_isEditing) const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: MsButton(
                                    label: _isEditing
                                        ? 'UPDATE RESPONSE'
                                        : 'SUBMIT RESPONSE 🚀',
                                    onPressed: prov.isActionLoading
                                        ? null
                                        : (_isEditing
                                              ? _handleUpdateResponse
                                              : _handleRespond),
                                    isLoading: prov.isActionLoading,
                                    backgroundColor: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
