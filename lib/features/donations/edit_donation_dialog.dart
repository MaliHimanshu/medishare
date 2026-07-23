import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/donation_model.dart';
import '../../providers/donation_provider.dart';

class EditDonationDialog extends StatefulWidget {
  final DonationModel donation;

  const EditDonationDialog({
    super.key,
    required this.donation,
  });

  @override
  State<EditDonationDialog> createState() => _EditDonationDialogState();
}

class _EditDonationDialogState extends State<EditDonationDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.donation.quantity.toString(),
    );
    _notesController = TextEditingController(
      text: widget.donation.notes,
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitEdit() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final donationProvider = context.read<DonationProvider>();

    final qty = int.tryParse(_quantityController.text.trim()) ?? widget.donation.quantity;
    final notes = _notesController.text.trim();

    final success = await donationProvider.editDonation(
      widget.donation.id,
      quantity: qty,
      notes: notes,
    );

    if (mounted) {
      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Donation updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        navigator.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(donationProvider.errorMessage.isNotEmpty
                ? donationProvider.errorMessage
                : 'Failed to update donation.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final equip = widget.donation.equipment;
    final maxQty = equip?.quantity ?? 999;
    final donationProvider = context.watch<DonationProvider>();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withAlpha(25),
            child: const Icon(Icons.edit_note, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          const Text(
            'Edit Donation',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Equipment: ${equip?.name ?? 'Donated Item'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),

              // Quantity Input
              const Text(
                'Quantity *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter quantity',
                  prefixIcon: const Icon(Icons.numbers, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Quantity is required';
                  }
                  final n = int.tryParse(val.trim());
                  if (n == null || n <= 0) {
                    return 'Quantity must be > 0';
                  }
                  if (n > maxQty) {
                    return 'Max available stock is $maxQty';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Notes Input
              const Text(
                'Notes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add or update notes...',
                  prefixIcon: const Icon(Icons.notes, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: donationProvider.isLoading ? null : _submitEdit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: donationProvider.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
