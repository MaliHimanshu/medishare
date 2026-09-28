import 'package:flutter/material.dart';
import '../otp/otp_screen.dart';

class OtpVerificationScreen extends StatelessWidget {
  final String phone;

  const OtpVerificationScreen({
    super.key,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return OtpScreen(
      target: phone,
      type: 'phone',
      isForgotPassword: false,
    );
  }
}
