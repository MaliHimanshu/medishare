import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/equipment_model.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/request_provider.dart';

class CreateRequestScreen extends StatefulWidget {
  final EquipmentModel? initialEquipment;

  const CreateRequestScreen({
    super.key,
    this.initialEquipment,
  });

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  EquipmentModel? _selectedEquipment;
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedEquipment = widget.initialEquipment;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EquipmentProvider>().fetchEquipment();
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEquipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select equipment to request.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final requestProvider = context.read<RequestProvider>();

    final qty = int.tryParse(_quantityController.text.trim()) ?? 1;

    final success = await requestProvider.createRequest(
      equipmentId: _selectedEquipment!.id,
      reason: _purposeController.text.trim(),
      quantity: qty,
      notes: _notesController.text.trim(),
    );

    if (mounted) {
      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Equipment request submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        navigator.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(requestProvider.errorMessage.isNotEmpty
                ? requestProvider.errorMessage
                : 'Failed to submit request.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = context.watch<EquipmentProvider>();
    final requestProvider = context.watch<RequestProvider>();

    final availableItems = equipmentProvider.equipment
        .where((item) => item.status.toUpperCase() == 'AVAILABLE')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Request Equipment'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
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
                      child: Icon(Icons.assignment_outlined, color: Colors.white),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request Medical Support',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Submit a request for medical equipment available in the MediShare network.',
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

              // Select Equipment Dropdown
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
                          'No available equipment currently listed.',
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
                    hintText: 'Choose equipment item',
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

              // Selected Equipment Details Card
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
                          child: const Icon(Icons.medical_information_outlined, color: AppColors.primary),
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
                                'Available Stock: ${_selectedEquipment!.quantity} units',
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

              // Quantity Input
              const Text(
                'Requested Quantity *',
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

              // Purpose Input
              const Text(
                'Purpose of Request *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _purposeController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Explain why this equipment is needed (min 5 chars)...',
                  prefixIcon: const Icon(Icons.medical_services_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Purpose is required';
                  }
                  if (val.trim().length < 5) {
                    return 'Purpose must be at least 5 characters long';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Additional Notes Input
              const Text(
                'Additional Notes (Optional)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Add hospital contact or special instructions...',
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: requestProvider.isLoading ? null : _submitRequest,
                  icon: requestProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    requestProvider.isLoading ? 'Submitting Request...' : 'Submit Request',
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
      ),
    );
  }
}
