import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/rental_model.dart';
import '../../providers/rental_provider.dart';

import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayCheckoutSheet extends StatefulWidget {
  final RentalModel rental;

  const RazorpayCheckoutSheet({super.key, required this.rental});

  @override
  State<RazorpayCheckoutSheet> createState() => _RazorpayCheckoutSheetState();
}

class _RazorpayCheckoutSheetState extends State<RazorpayCheckoutSheet> {
  late Razorpay _razorpay;
  String? _currentOrderId;
  bool _isProcessing = false;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('[PAYMENT] Payment success callback received');
    final rentalProvider = context.read<RentalProvider>();

    debugPrint('[PAYMENT] Verifying payment on server...');
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final isVerified = await rentalProvider.verifyPayment(
      rentalId: widget.rental.id,
      razorpayOrderId: response.orderId ?? _currentOrderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
      razorpaySignature: response.signature ?? '',
    );

    if (isVerified) {
      debugPrint('[PAYMENT] Verification successful');
      debugPrint('[PAYMENT] Rental marked PAID');
      setState(() {
        _isProcessing = false;
        _isSuccess = true;
      });
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.pop(context, true);
    } else {
      debugPrint('[PAYMENT] Verification failed');
      await rentalProvider.recordPaymentFailure(widget.rental.id);
      setState(() {
        _isProcessing = false;
        _errorMessage = rentalProvider.errorMessage.isNotEmpty
            ? rentalProvider.errorMessage
            : 'Server-side payment verification failed.';
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    debugPrint('[PAYMENT] Payment error/cancelled: ${response.message}');
    final rentalProvider = context.read<RentalProvider>();
    await rentalProvider.recordPaymentFailure(widget.rental.id);
    setState(() {
      _isProcessing = false;
      _errorMessage = 'Payment failed or cancelled: ${response.message ?? ""}';
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('[PAYMENT] External wallet selected: ${response.walletName}');
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final rentalProvider = context.read<RentalProvider>();

    try {
      debugPrint('[PAYMENT] Creating order for rental ${widget.rental.id}');
      final orderData = await rentalProvider.createPaymentOrder(
        widget.rental.id,
      );

      if (orderData == null) {
        setState(() {
          _isProcessing = false;
          _errorMessage = rentalProvider.errorMessage.isNotEmpty
              ? rentalProvider.errorMessage
              : 'Failed to initialize payment order.';
        });
        return;
      }

      final orderId = orderData['orderId']?.toString() ?? '';
      _currentOrderId = orderId;
      debugPrint('[PAYMENT] Order created: $orderId');

      final amount = orderData['amount'];
      final keyId = orderData['keyId'];
      final equipmentName = orderData['equipmentName'] ?? "Medical Equipment";
      final renterPhone = orderData['renterPhone'] ?? "";
      final renterEmail = orderData['renterEmail'] ?? "";

      var options = {
        'key': keyId,
        'amount': amount, // in paise
        'name': 'MediShare',
        'order_id': orderId,
        'description': 'Rental for $equipmentName',
        'timeout': 300, // 5 minutes
        'prefill': {
          'contact': renterPhone,
          'email': renterEmail,
        },
        'theme': {
          'color': '#0C2340'
        }
      };

      debugPrint('[PAYMENT] Checkout opened');
      _razorpay.open(options);
    } catch (e) {
      await rentalProvider.recordPaymentFailure(widget.rental.id);
      setState(() {
        _isProcessing = false;
        _errorMessage =
            'Payment error: ${e.toString().replaceAll("Exception: ", "")}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final equip = widget.rental.equipment;

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Razorpay badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            "Razorpay",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.withAlpha(80)),
                      ),
                      child: const Text(
                        "100% SECURE",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close, color: context.textPrimaryColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Order Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          equip?.name ?? "Medical Equipment Rental",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: context.textPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${widget.rental.numberOfDays} day(s)",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Rental Amount:",
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            "₹${widget.rental.rentalAmount.toStringAsFixed(0)}",
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
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Security Deposit:",
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            "₹${widget.rental.securityDeposit.toStringAsFixed(0)}",
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
                  Divider(height: 18, color: context.borderColor),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Total Payable:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
                            "₹${widget.rental.totalAmount.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
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

            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSuccess
                      ? AppColors.success
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                onPressed: _isProcessing || _isSuccess ? null : _processPayment,
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Initializing Payment...",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    : _isSuccess
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Payment Verified & Approved!",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "Pay ₹${widget.rental.totalAmount.toStringAsFixed(0)} via Razorpay",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
