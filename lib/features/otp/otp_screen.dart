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
import '../home/home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String target;
  final String type; // 'email' or 'phone'
  final bool isForgotPassword;
  final String? initialErrorMessage;

  const OtpScreen({
    super.key,
    required this.target,
    required this.type,
    this.isForgotPassword = true,
    this.initialErrorMessage,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with TickerProviderStateMixin {
  static const int _otpLength = 6;
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;

  // Timer (30-second countdown)
  Timer? _resendTimer;
  int _secondsRemaining = 30;
  bool get _canResend => _secondsRemaining == 0;
  bool get _isOtpComplete =>
      _controllers.every((c) => c.text.trim().isNotEmpty) &&
      _controllers.map((c) => c.text.trim()).join().length == _otpLength;

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

    if (widget.initialErrorMessage != null && widget.initialErrorMessage!.isNotEmpty) {
      _errorMessage = widget.initialErrorMessage;
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
    if (!_canResend || _isResending || _isVerifying) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();

    // Clear existing input
    for (var ctrl in _controllers) {
      ctrl.clear();
    }
    _focusNodes[0].requestFocus();

    try {
      final success = widget.isForgotPassword
          ? await auth.sendForgotPasswordOtp(widget.target, widget.type)
          : await auth.resendOtp(widget.target);
      if (!mounted) return;

      if (success) {
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to ${_getFormattedTarget(widget.target, widget.type)} 📲'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        setState(() {
          _errorMessage = auth.errorMessage ?? "Failed to resend OTP";
        });
        _shakeCtrl.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
        _shakeCtrl.forward(from: 0.0);
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
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

  String _getFormattedTarget(String target, String type) {
    if (type == 'email') return target;
    final clean = target.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10) {
      return '+91 ${clean.substring(0, 5)} ${clean.substring(5)}';
    } else if (clean.length == 12 && clean.startsWith('91')) {
      return '+91 ${clean.substring(2, 7)} ${clean.substring(7)}';
    }
    return target;
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
      if (clean.length == 10) {
        return '+91 ${clean.substring(0, 5)} ${clean.substring(5)}';
      } else if (clean.length == 12 && clean.startsWith('91')) {
        return '+91 ${clean.substring(2, 7)} ${clean.substring(7)}';
      }
      return target;
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < _otpLength) {
      setState(() => _errorMessage = 'Please enter complete 6-digit code');
      _shakeCtrl.forward(from: 0.0);
      return;
    }

    if (_isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();

      if (widget.isForgotPassword) {
        final resetToken = await auth.verifyForgotPasswordOtp(
          widget.target,
          widget.type,
          otp,
        );

        if (!mounted) return;

        if (resetToken != null && resetToken.isNotEmpty) {
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
            _errorMessage = auth.errorMessage ?? "Invalid or expired OTP";
          });
          _shakeCtrl.forward(from: 0.0);
        }
      } else {
        final success = await auth.verifyOtp(widget.target, otp);

        if (!mounted) return;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Phone number verified successfully! 🎉'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );

          if (auth.isAuthenticated) {
            Navigator.pushAndRemoveUntil(
              context,
              AppPageTransitions.slideRight(const HomeScreen()),
              (route) => false,
            );
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context, true);
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              AppPageTransitions.slideRight(const HomeScreen()),
              (route) => false,
            );
          }
        } else {
          setState(() {
            _errorMessage = auth.errorMessage ?? "Invalid or expired OTP";
          });
          _shakeCtrl.forward(from: 0.0);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
        _shakeCtrl.forward(from: 0.0);
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
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

              // Error Message with Shake & Category
              if (_errorMessage != null)
                AnimatedBuilder(
                  animation: _shakeCtrl,
                  builder: (context, child) {
                    final shakeOffset = math.sin(_shakeCtrl.value * math.pi * 4) * 8.0;
                    final msg = _errorMessage!.toLowerCase();
                    final isExpired = msg.contains('expire');
                    final isInvalid = msg.contains('invalid') || msg.contains('incorrect') || msg.contains('wrong');
                    final isNetwork = msg.contains('timed out') || msg.contains('network') || msg.contains('reach the server') || msg.contains('connection');
                    final isServer = msg.contains('server') || msg.contains('500');

                    String categoryTitle = "Verification Error";
                    if (isExpired) {
                      categoryTitle = "Expired OTP";
                    } else if (isInvalid) {
                      categoryTitle = "Invalid OTP";
                    } else if (isNetwork) {
                      categoryTitle = "Network Error";
                    } else if (isServer) {
                      categoryTitle = "Server Error";
                    }

                    return Transform.translate(
                      offset: Offset(shakeOffset, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withAlpha(60)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    categoryTitle,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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
                    gradient: (_isOtpComplete && !_isVerifying)
                        ? const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                          )
                        : LinearGradient(
                            colors: [
                              context.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                              context.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                            ],
                          ),
                    boxShadow: (_isOtpComplete && !_isVerifying)
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(50),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            )
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: (_isOtpComplete && !_isVerifying) ? _verifyOtp : null,
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
                            : Text(
                                "Verify OTP →",
                                style: TextStyle(
                                  color: (_isOtpComplete && !_isVerifying)
                                      ? Colors.white
                                      : (context.isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600),
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
                    const SizedBox(height: 8),
                    if (_isResending)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Sending OTP...",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      )
                    else
                      GestureDetector(
                        onTap: (_canResend && !_isVerifying) ? _handleResend : null,
                        child: Text(
                          _canResend
                              ? "Resend OTP (available) →"
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