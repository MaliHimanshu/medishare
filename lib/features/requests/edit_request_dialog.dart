import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/request_model.dart';
import '../../providers/request_provider.dart';

class EditRequestDialog extends StatefulWidget {
  final RequestModel request;

  const EditRequestDialog({
    super.key,
    required this.request,
  });

  @override
  State<EditRequestDialog> createState() => _EditRequestDialogState();
}

class _EditRequestDialogState extends State<EditRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  late TextEditingController _purposeController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.request.quantity.toString(),
    );
    _purposeController = TextEditingController(
      text: widget.request.reason,
    );
    _notesController = TextEditingController(
      text: widget.request.notes,
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitEdit() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final requestProvider = context.read<RequestProvider>();

    final qty = int.tryParse(_quantityController.text.trim()) ?? widget.request.quantity;
    final purpose = _purposeController.text.trim();
    final notes = _notesController.text.trim();

    final success = await requestProvider.editRequest(
      widget.request.id,
      quantity: qty,
      reason: purpose,
      notes: notes,
    );

    if (mounted) {
      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Request updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        navigator.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(requestProvider.errorMessage.isNotEmpty
                ? requestProvider.errorMessage
                : 'Failed to update request.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final equip = widget.request.equipment;
    final maxQty = equip?.quantity ?? 999;
    final requestProvider = context.watch<RequestProvider>();

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
            'Edit Request',
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
                'Equipment: ${equip?.name ?? 'Requested Item'}',
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

              // Purpose Input
              const Text(
                'Purpose of Request *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _purposeController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Reason for request...',
                  prefixIcon: const Icon(Icons.medical_services_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(12),
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

              const SizedBox(height: 16),

              // Additional Notes Input
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
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Additional notes or hospital info...',
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
          onPressed: requestProvider.isLoading ? null : _submitEdit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: requestProvider.isLoading
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
