import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_page_transitions.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/ms_logo.dart';
import '../home/home_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phone;

  const OtpVerificationScreen({
    super.key,
    required this.phone,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> with TickerProviderStateMixin {
  final int _otpLength = 6;
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;

  bool _isVerifying = false;
  String? _errorMessage;

  // Timer
  Timer? _resendTimer;
  int _secondsRemaining = 30;
  bool get _canResend => _secondsRemaining == 0;

  // Animations
  late AnimationController _entranceCtrl;
  late Animation<double> _logoFade;
  late Animation<Offset> _formSlide;

  late AnimationController _shakeCtrl;

  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(_otpLength, (index) => FocusNode());
    _controllers = List.generate(_otpLength, (index) => TextEditingController());

    // Listeners for focus changes to trigger UI updates (like active border)
    for (var node in _focusNodes) {
      node.addListener(() => setState(() {}));
    }

    _startResendTimer();

    // Entrance Animation
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)));
    _entranceCtrl.forward();

    // Shake Animation
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
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
    setState(() => _secondsRemaining = 30);
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
    
    // Clear current OTP
    for (var ctrl in _controllers) {
      ctrl.clear();
    }
    _focusNodes[0].requestFocus();
    
    final success = await auth.resendOtp(widget.phone);
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

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Automatically verify if all filled
        if (_controllers.every((c) => c.text.isNotEmpty)) {
          _verifyOtp();
        }
      }
    }
    setState(() {
      _errorMessage = null; // Clear error on typing
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

  String _getMaskedPhone(String phone) {
    if (phone.length < 10) return phone;
    // e.g., 9876543210 -> +91 •••••• 3210 (Assuming India for example, or just masked)
    final last4 = phone.substring(phone.length - 4);
    return "+91 •••••• $last4"; // Simple mask for demonstration
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < _otpLength) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(widget.phone, otp);

    if (!mounted) return;

    if (success) {
      setState(() {
        _isVerifying = false;
        _isSuccess = true;
      });
      
      // Navigate after success animation
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            AppPageTransitions.slideRight(const HomeScreen()),
            (route) => false,
          );
        }
      });
    } else {
      setState(() {
        _isVerifying = false;
        _errorMessage = auth.errorMessage ?? "Verification failed";
      });
      // Shake animation
      _shakeCtrl.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boxSize = (screenWidth - 48 - ((_otpLength - 1) * 8)) / _otpLength;
    final actualBoxSize = boxSize.clamp(40.0, 58.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Ambient Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF12B8A6).withValues(alpha: 0.15),
                    const Color(0xFF2563EB).withValues(alpha: 0.05),
                    const Color(0xFFF6F8FC).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Logo
                  FadeTransition(
                    opacity: _logoFade,
                    child: const Center(child: MsLogo(height: 38)),
                  ),
                  
                  const SizedBox(height: 40),

                  // Illustration (Premium combination)
                  SlideTransition(
                    position: _formSlide,
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.smartphone, size: 48, color: Color(0xFF14213D)),
                          Positioned(
                            bottom: 20,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF12B8A6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, size: 16, color: Colors.white),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // Texts
                  SlideTransition(
                    position: _formSlide,
                    child: Column(
                      children: [
                        const Text(
                          "Verify your mobile",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF14213D),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Enter the 6-digit code we sent to your mobile number.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getMaskedPhone(widget.phone),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF14213D),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                "Edit number",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // OTP Input Boxes
                  SlideTransition(
                    position: _formSlide,
                    child: _isSuccess ? _buildSuccessState() : _buildOtpFields(actualBoxSize),
                  ),

                  const SizedBox(height: 24),

                  // Error Message
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
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    ),

                  const SizedBox(height: 32),

                  // Verify Button
                  SlideTransition(
                    position: _formSlide,
                    child: _isSuccess 
                      ? const SizedBox.shrink()
                      : Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF12B8A6), Color(0xFF2563EB)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
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
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                      )
                                    : const Text(
                                        "Verify & Continue →",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                  ),

                  const SizedBox(height: 32),

                  // Resend
                  SlideTransition(
                    position: _formSlide,
                    child: _isSuccess
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            const Text(
                              "Didn't receive the code?",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _handleResend,
                              child: Text(
                                _canResend 
                                    ? "Resend OTP" 
                                    : "Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _canResend ? const Color(0xFF2563EB) : AppColors.textSecondary.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
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
          height: size + 6,
          child: KeyboardListener(
            focusNode: FocusNode(), // Dummy focus node to capture key events without stealing focus from TextField
            onKeyEvent: (event) => _onKey(event, index),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF14213D),
              ),
              onChanged: (value) => _onChanged(value, index),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                counterText: "",
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF12B8A6), width: 2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Column(
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF12B8A6).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF12B8A6), size: 60),
              ),
              const SizedBox(height: 16),
              const Text(
                "Mobile verified!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF14213D),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
