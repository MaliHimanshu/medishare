import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_page_transitions.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/ms_logo.dart';
import '../reset_password/reset_password_screen.dart';

class OtpScreen extends StatefulWidget {
  final String target;
  final String type; // 'email' or 'phone'

  const OtpScreen({
    super.key,
    required this.target,
    required this.type,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with TickerProviderStateMixin {
  static const int _otpLength = 6;
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;

  bool _isVerifying = false;
  String? _errorMessage;

  // Timer
  Timer? _resendTimer;
  int _secondsRemaining = 60;
  bool get _canResend => _secondsRemaining == 0;

  // Animations
  late AnimationController _entranceCtrl;
  late Animation<double> _logoFade;
  late Animation<Offset> _formSlide;
  late AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    _controllers = List.generate(_otpLength, (_) => TextEditingController());

    for (var node in _focusNodes) {
      node.addListener(() => setState(() {}));
    }

    _startResendTimer();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );
    _entranceCtrl.forward();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _entranceCtrl.dispose();
    _shakeCtrl.dispose();
    for (var ctrl in _controllers) {
      ctrl.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _secondsRemaining = 60);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleResend() async {
    if (!_canResend || _isVerifying) return;

    final auth = context.read<AuthProvider>();

    // Clear existing input
    for (var ctrl in _controllers) {
      ctrl.clear();
    }
    _focusNodes[0].requestFocus();

    final success = await auth.sendForgotPasswordOtp(widget.target, widget.type);
    if (!mounted) return;

    if (success) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('New verification code sent'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      setState(() {
        _errorMessage = auth.errorMessage ?? "Failed to resend OTP";
      });
    }
  }

  void _fillPastedOtp(String pastedText) {
    final cleanDigits = pastedText.replaceAll(RegExp(r'\D'), '');
    if (cleanDigits.length >= _otpLength) {
      for (int i = 0; i < _otpLength; i++) {
        _controllers[i].text = cleanDigits[i];
      }
      _focusNodes[_otpLength - 1].requestFocus();
      _verifyOtp();
    }
  }

  void _onChanged(String value, int index) {
    if (value.length > 1) {
      // User pasted into input
      _fillPastedOtp(value);
      return;
    }

    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_controllers.every((c) => c.text.isNotEmpty)) {
          _verifyOtp();
        }
      }
    }
    setState(() {
      _errorMessage = null;
    });
  }

  void _onKey(KeyEvent event, int index) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
      }
    }
  }

  String _getMaskedTarget(String target, String type) {
    if (type == 'email') {
      final parts = target.split('@');
      if (parts.length < 2) return target;
      final name = parts[0];
      final domain = parts[1];
      if (name.length <= 2) return '$name***@$domain';
      return '${name.substring(0, 2)}***${name.substring(name.length - 1)}@$domain';
    } else {
      final clean = target.replaceAll(RegExp(r'\D'), '');
      if (clean.length < 6) return target;
      final last4 = clean.substring(clean.length - 4);
      return '+${clean.substring(0, math.min(2, clean.length - 4))} •••••• $last4';
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < _otpLength) {
      setState(() => _errorMessage = 'Please enter complete 6-digit code');
      _shakeCtrl.forward(from: 0.0);
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final resetToken = await auth.verifyForgotPasswordOtp(
      widget.target,
      widget.type,
      otp,
    );

    if (!mounted) return;

    if (resetToken != null && resetToken.isNotEmpty) {
      setState(() => _isVerifying = false);

      Navigator.pushReplacement(
        context,
        AppPageTransitions.slideRight(
          ResetPasswordScreen(
            target: widget.target,
            type: widget.type,
            resetToken: resetToken,
          ),
        ),
      );
    } else {
      setState(() {
        _isVerifying = false;
        _errorMessage = auth.errorMessage ?? "Invalid verification code";
      });
      _shakeCtrl.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boxWidth = ((screenWidth - 48 - ((_otpLength - 1) * 8)) / _otpLength).clamp(42.0, 56.0);

    final isEmail = widget.type == 'email';
    final subtitleText = isEmail
        ? "Enter the 6-digit OTP sent to your email"
        : "Enter the 6-digit OTP sent to your phone";

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              FadeTransition(
                opacity: _logoFade,
                child: const Center(child: MsLogo(height: 40)),
              ),
              const SizedBox(height: 32),

              SlideTransition(
                position: _formSlide,
                child: Container(
                  height: 84,
                  width: 84,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEmail ? Icons.mark_email_read_rounded : Icons.phonelink_ring_rounded,
                    size: 42,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title & Subtitle
              SlideTransition(
                position: _formSlide,
                child: Column(
                  children: [
                    Text(
                      "Verify OTP",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimaryColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitleText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textSecondaryColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getMaskedTarget(widget.target, widget.type),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            "Change",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // OTP Input Boxes
              SlideTransition(
                position: _formSlide,
                child: _buildOtpFields(boxWidth),
              ),

              const SizedBox(height: 20),

              // Error Message with Shake
              if (_errorMessage != null)
                AnimatedBuilder(
                  animation: _shakeCtrl,
                  builder: (context, child) {
                    final shakeOffset = math.sin(_shakeCtrl.value * math.pi * 4) * 8.0;
                    return Transform.translate(
                      offset: Offset(shakeOffset, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 28),

              // Verify Button
              SlideTransition(
                position: _formSlide,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(50),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isVerifying ? null : _verifyOtp,
                      child: Center(
                        child: _isVerifying
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "Verify OTP →",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Resend Timer & Button
              SlideTransition(
                position: _formSlide,
                child: Column(
                  children: [
                    Text(
                      "Didn't receive the code?",
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _handleResend,
                      child: Text(
                        _canResend
                            ? "Resend OTP"
                            : "Resend OTP in ${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _canResend ? AppColors.primary : context.textSecondaryColor.withAlpha(120),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpFields(double size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        _otpLength,
        (index) => SizedBox(
          width: size,
          height: size + 8,
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) => _onKey(event, index),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.textPrimaryColor,
              ),
              onChanged: (value) => _onChanged(value, index),
              decoration: InputDecoration(
                filled: true,
                fillColor: context.isDarkMode ? AppColors.dark2 : Colors.white,
                counterText: "",
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: context.isDarkMode ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: context.isDarkMode ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}