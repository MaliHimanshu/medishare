import 'package:flutter/material.dart';
import '../otp/otp_screen.dart';

class OtpVerificationScreen extends StatelessWidget {
  final String phone;
  final String? initialErrorMessage;

  const OtpVerificationScreen({
    super.key,
    required this.phone,
    this.initialErrorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return OtpScreen(
      target: phone,
      type: 'phone',
      isForgotPassword: false,
      initialErrorMessage: initialErrorMessage,
    );
  }
}
