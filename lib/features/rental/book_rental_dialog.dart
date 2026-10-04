import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/equipment_model.dart';
import '../../providers/rental_provider.dart';

class BookRentalDialog extends StatefulWidget {
  final EquipmentModel equipment;

  const BookRentalDialog({super.key, required this.equipment});

  @override
  State<BookRentalDialog> createState() => _BookRentalDialogState();
}

class _BookRentalDialogState extends State<BookRentalDialog> {
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 4));
  bool _isSubmitting = false;
  bool _agreementAccepted = false;

  int get _numberOfDays {
    final diff = _endDate.difference(_startDate).inDays;
    return diff > 0 ? diff : 1;
  }

  /// Returns the per-day price from the equipment, or null if not set.
  /// DO NOT fall back to 0 — null means the backend data is missing.
  double? get _rentalPricePerDay => widget.equipment.rentalPricePerDay;
  double? get _securityDeposit => widget.equipment.securityDeposit;

  /// True only when the backend has supplied a valid (> 0) rental price.
  bool get _hasPricingData =>
      _rentalPricePerDay != null && _rentalPricePerDay! > 0;

  double get _rentalAmount => (_rentalPricePerDay ?? 0) * _numberOfDays;
  double get _totalAmount => _rentalAmount + (_securityDeposit ?? 0);

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate) ||
            _endDate.isAtSameMomentAs(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isAfter(_startDate)
          ? _endDate
          : _startDate.add(const Duration(days: 1)),
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    // Block booking if the backend did not provide a rental price
    if (!_hasPricingData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Rental price not available for this equipment. Please contact the owner.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_agreementAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the rental agreement terms.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = context.read<RentalProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final createdRental = await provider.createRental(
      equipmentId: widget.equipment.id,
      startDate: _startDate,
      endDate: _endDate,
      rentalPricePerDay: _rentalPricePerDay,
      securityDeposit: _securityDeposit,
      totalAmount: _totalAmount,
      agreementAccepted: _agreementAccepted,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (createdRental != null) {
        navigator.pop(createdRental);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage.isNotEmpty
                  ? provider.errorMessage
                  : "Failed to submit rental request.",
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.borderColor),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Rent ${widget.equipment.name}",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select your rental period:",
              style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
            ),
            const SizedBox(height: 14),

            // Date Pickers Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectStartDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: context.borderColor),
                        borderRadius: BorderRadius.circular(12),
                        color: context.inputBg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Start Date",
                            style: TextStyle(
                              fontSize: 10,
                              color: context.textSecondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${_startDate.day}/${_startDate.month}/${_startDate.year}",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _selectEndDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: context.borderColor),
                        borderRadius: BorderRadius.circular(12),
                        color: context.inputBg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "End Date",
                            style: TextStyle(
                              fontSize: 10,
                              color: context.textSecondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${_endDate.day}/${_endDate.month}/${_endDate.year}",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (!_hasPricingData)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withAlpha(80)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Rental price is not configured for this equipment. Booking is currently unavailable.",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              // Rental Calculation Summary Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Duration:",
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "$_numberOfDays day(s)",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Rate (₹${(_rentalPricePerDay ?? 0).toStringAsFixed(0)} × $_numberOfDays):",
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              "₹${_rentalAmount.toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if ((_securityDeposit ?? 0) > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "Security Deposit (Refundable):",
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                "₹${(_securityDeposit ?? 0).toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    Divider(height: 16, color: context.borderColor),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Total Amount:",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              "₹${_totalAmount.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (_hasPricingData) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _agreementAccepted,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _agreementAccepted = val ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _agreementAccepted = !_agreementAccepted;
                        });
                      },
                      child: Text(
                        "I accept the rental agreement terms & conditions.",
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Cancel",
            style: TextStyle(color: context.textSecondaryColor),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: (_isSubmitting || !_hasPricingData) ? null : _submitBooking,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text("Confirm Booking"),
        ),
      ],
    );
  }
}
