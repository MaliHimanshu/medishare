// Create Emergency Alert Screen
// File: lib/features/emergency_alerts/create_emergency_alert_screen.dart
//
// Allows Hospital administrators to broadcast urgent equipment requirements
// to eligible NGOs with high-priority push and sound alerts.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_page_transitions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/emergency_alert_provider.dart';
import '../../shared/widgets/ms_button.dart';
import '../../shared/widgets/ms_text_field.dart';
import 'hospital_emergency_alerts_screen.dart';

class CreateEmergencyAlertScreen extends StatefulWidget {
  const CreateEmergencyAlertScreen({super.key});

  @override
  State<CreateEmergencyAlertScreen> createState() =>
      _CreateEmergencyAlertScreenState();
}

class _CreateEmergencyAlertScreenState
    extends State<CreateEmergencyAlertScreen> {
  final _formKey = GlobalKey<FormState>();

  final _equipmentNameCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '10');
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  String _selectedPriority = 'CRITICAL';
  String? _selectedCategory;
  DateTime? _expiresAt;

  final List<String> _equipmentSuggestions = [
    'Oxygen Cylinders',
    'Wheelchairs',
    'ICU Patient Beds',
    'Ventilators',
    'Infusion Pumps',
    'Cardiac Monitors',
    'Suction Machines',
    'Defibrillators',
  ];

  final List<String> _categories = [
    'Respiratory',
    'Mobility',
    'Critical Care',
    'Hospital Furniture',
    'Diagnostic',
    'Surgical',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null && user.address != null) {
      _locationCtrl.text = user.address!;
    }
  }

  @override
  void dispose() {
    _equipmentNameCtrl.dispose();
    _quantityCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'CRITICAL':
        return const Color(0xFFDC2626); // Crimson
      case 'HIGH':
        return const Color(0xFFEA580C); // Orange
      case 'NORMAL':
      default:
        return const Color(0xFF2563EB); // Blue
    }
  }

  Future<void> _pickExpiryDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 23, minute: 59),
      );

      if (time != null) {
        setState(() {
          _expiresAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _handleConfirmAndSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final quantity = int.tryParse(_quantityCtrl.text.trim()) ?? 0;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be greater than zero')),
      );
      return;
    }

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFDC2626),
              size: 28,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Send Emergency Alert?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will immediately broadcast a high-priority alert to all eligible NGOs with loud alert sounds and push notifications.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withAlpha(60)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🚨 ${_equipmentNameCtrl.text.trim()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Quantity Required: $quantity units'),
                  Text('Priority: $_selectedPriority'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Send Alert 🚨',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final prov = context.read<EmergencyAlertProvider>();
    final success = await prov.createAlert(
      equipmentName: _equipmentNameCtrl.text.trim(),
      equipmentCategory: _selectedCategory,
      quantityRequired: quantity,
      priority: _selectedPriority,
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      address: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      expiresAt: _expiresAt,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '🚨 Emergency alert sent successfully to eligible NGOs!',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        AppPageTransitions.slideRight(const HospitalEmergencyAlertsScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            prov.errorMessage ?? 'Failed to broadcast emergency alert',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<EmergencyAlertProvider>();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          '🚨 Create Emergency Alert',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Urgent Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withAlpha(40),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.crisis_alert_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Instant NGO Mobilization',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Broadcast your critical medical apparatus shortage to all active partner NGOs in real time.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Equipment Name Field
                Text(
                  'Equipment Required *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                MsTextField(
                  label: 'Equipment Name',
                  hint: 'e.g. Oxygen Cylinders',
                  controller: _equipmentNameCtrl,
                  prefixIcon: Icons.medical_services_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Equipment name is required'
                      : null,
                ),
                const SizedBox(height: 10),

                // Quick suggestions chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _equipmentSuggestions.map((item) {
                    final selected = _equipmentNameCtrl.text == item;
                    return ActionChip(
                      label: Text(
                        item,
                        style: TextStyle(
                          fontSize: 12,
                          color: selected
                              ? Colors.white
                              : context.textPrimaryColor,
                        ),
                      ),
                      backgroundColor: selected
                          ? AppColors.primary
                          : context.cardColor,
                      onPressed: () {
                        setState(() {
                          _equipmentNameCtrl.text = item;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Quantity & Category Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quantity
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quantity Required *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          MsTextField(
                            label: 'Quantity',
                            hint: '20',
                            controller: _quantityCtrl,
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.format_list_numbered_rounded,
                            validator: (v) {
                              final num = int.tryParse(v ?? '');
                              if (num == null || num <= 0) return '> 0';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Category
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 54,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: context.isDarkMode
                                    ? Colors.grey.shade800
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                hint: const Text(
                                  'Category',
                                  style: TextStyle(fontSize: 14),
                                ),
                                isExpanded: true,
                                items: _categories.map((c) {
                                  return DropdownMenuItem<String>(
                                    value: c,
                                    child: Text(
                                      c,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedCategory = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Priority Selection
                Text(
                  'Alert Priority *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['CRITICAL', 'HIGH', 'NORMAL'].map((p) {
                    final selected = _selectedPriority == p;
                    final color = _getPriorityColor(p);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPriority = p),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withAlpha(30)
                                : context.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? color : Colors.grey.shade300,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                p == 'CRITICAL'
                                    ? Icons.local_fire_department_rounded
                                    : Icons.priority_high_rounded,
                                color: color,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: selected
                                      ? color
                                      : context.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Hospital Location
                Text(
                  'Hospital Location *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                MsTextField(
                  label: 'Hospital Address / Receiving Bay',
                  hint: 'e.g. Trauma Center Gate 2, Civil Hospital, Ahmedabad',
                  controller: _locationCtrl,
                  prefixIcon: Icons.location_on_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Hospital location is required'
                      : null,
                ),
                const SizedBox(height: 20),

                // Description
                Text(
                  'Emergency Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                MsTextField(
                  label: 'Describe emergency and urgency',
                  hint:
                      'e.g. Major accident on highway; 15 patients requiring supplemental oxygen urgently.',
                  controller: _descriptionCtrl,
                  maxLines: 3,
                  prefixIcon: Icons.description_outlined,
                ),
                const SizedBox(height: 20),

                // Expiry Date/Time
                Text(
                  'Required Until (Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickExpiryDateTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: context.isDarkMode
                            ? Colors.grey.shade800
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _expiresAt == null
                              ? 'No expiration set (Tap to set deadline)'
                              : 'Expires: ${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year} at ${_expiresAt!.hour}:${_expiresAt!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 13,
                            color: _expiresAt == null
                                ? context.textSecondaryColor
                                : context.textPrimaryColor,
                            fontWeight: _expiresAt == null
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (_expiresAt != null)
                          GestureDetector(
                            onTap: () => setState(() => _expiresAt = null),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Send Button
                MsButton(
                  label: prov.isActionLoading
                      ? 'Broadcasting Alert...'
                      : 'SEND EMERGENCY ALERT 🚨',
                  onPressed: prov.isActionLoading
                      ? null
                      : _handleConfirmAndSubmit,
                  isLoading: prov.isActionLoading,
                  backgroundColor: const Color(0xFFDC2626),
                  icon: Icons.send_rounded,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
