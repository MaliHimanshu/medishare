import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/equipment_model.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/donation_provider.dart';

class CreateDonationScreen extends StatefulWidget {
  const CreateDonationScreen({super.key});

  @override
  State<CreateDonationScreen> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends State<CreateDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  EquipmentModel? _selectedEquipment;
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EquipmentProvider>().fetchEquipment();
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEquipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an equipment to donate.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final donationProvider = context.read<DonationProvider>();

    final qty = int.tryParse(_quantityController.text.trim()) ?? 1;

    final success = await donationProvider.createDonation(
      equipmentId: _selectedEquipment!.id,
      quantity: qty,
      note: _noteController.text.trim(),
    );

    if (mounted) {
      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Donation listed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        navigator.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(donationProvider.errorMessage.isNotEmpty
                ? donationProvider.errorMessage
                : 'Failed to create donation.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = context.watch<EquipmentProvider>();
    final donationProvider = context.watch<DonationProvider>();

    // Available equipment items
    final availableItems = equipmentProvider.equipment
        .where((item) => item.status.toUpperCase() == 'AVAILABLE')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Donate Equipment'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Card ─────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.volunteer_activism, color: Colors.white),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Donate & Save Lives',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Select an available equipment to publish for donation in MediShare network.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Select Equipment Dropdown ───────────────────────
              const Text(
                'Select Equipment *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              if (equipmentProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                )
              else if (availableItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No available equipment found in your listings. Please add an equipment listing first.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<EquipmentModel>(
                  initialValue: _selectedEquipment,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Choose equipment to donate',
                    prefixIcon: const Icon(Icons.medical_services_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  items: availableItems.map((item) {
                    return DropdownMenuItem<EquipmentModel>(
                      value: item,
                      child: Text(
                        '${item.name} (${item.category})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedEquipment = val;
                      if (val != null) {
                        _quantityController.text = '1';
                      }
                    });
                  },
                  validator: (val) => val == null ? 'Please select equipment' : null,
                ),

              // Selected Equipment Details Card Preview
              if (_selectedEquipment != null) ...[
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: AppColors.primary.withAlpha(15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppColors.primary.withAlpha(40)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withAlpha(30),
                          child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedEquipment!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Category: ${_selectedEquipment!.category} • Condition: ${_selectedEquipment!.condition}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'Available Stock: ${_selectedEquipment!.quantity}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Quantity Input ──────────────────────────────────
              const Text(
                'Quantity *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter quantity',
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Quantity is required';
                  }
                  final n = int.tryParse(val.trim());
                  if (n == null || n <= 0) {
                    return 'Quantity must be greater than 0';
                  }
                  if (_selectedEquipment != null && n > _selectedEquipment!.quantity) {
                    return 'Quantity cannot exceed available stock (${_selectedEquipment!.quantity})';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ── Optional Note Input ─────────────────────────────
              const Text(
                'Optional Note',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add any special instructions or pickup note...',
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),

              const SizedBox(height: 32),

              // ── Submit Button ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: donationProvider.isLoading ? null : _submitDonation,
                  icon: donationProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.volunteer_activism_outlined),
                  label: Text(
                    donationProvider.isLoading ? 'Submitting...' : 'Submit Donation',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
