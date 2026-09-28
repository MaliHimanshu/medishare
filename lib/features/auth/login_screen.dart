import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_page_transitions.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/ms_button.dart';
import '../../shared/widgets/ms_logo.dart';
import '../../shared/widgets/ms_text_field.dart';
import '../home/home_screen.dart';
import '../forgot_password/forgot_password_screen.dart';
import 'register_screen.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _isPhoneMode = false;
  bool _isSendingOtp = false;

  String? _emailError;
  String? _passError;
  String? _phoneError;

  late AnimationController _animCtrl;
  late Animation<double> _logoFade;
  late Animation<Offset> _formSlide;
  late Animation<double> _formFade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _emailError = _validateEmail(_emailCtrl.text);
      _passError  = _validatePassword(_passCtrl.text);
    });

    if (_emailError != null || _passError != null) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back, ${auth.user?.name.split(' ').first ?? 'there'}! 👋'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.pushReplacement(
        context,
        AppPageTransitions.slideRight(const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Login failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _handleSendOtp() async {
    final rawPhone = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (rawPhone.isEmpty) {
      setState(() => _phoneError = 'Mobile number is required');
      return;
    }
    if (rawPhone.length != 10) {
      setState(() => _phoneError = 'Enter a valid 10-digit mobile number');
      return;
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(rawPhone)) {
      setState(() => _phoneError = 'Enter a valid Indian mobile number starting with 6-9');
      return;
    }

    final formattedPhone = '+91$rawPhone';
    setState(() {
      _phoneError = null;
      _isSendingOtp = true;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.sendOtp(formattedPhone);

    if (!mounted) return;
    setState(() => _isSendingOtp = false);

    if (success) {
      final masked = '+91 ${rawPhone.substring(0, 5)} ${rawPhone.substring(5)}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to $masked 📲'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.push(
        context,
        AppPageTransitions.slideRight(
          OtpVerificationScreen(phone: formattedPhone),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to send OTP'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthProvider>();
    final isLoading = auth.isLoading;

    return Scaffold(
      // Fix: use theme-aware background color
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // ── Logo (animated fade) ────────────────────
                FadeTransition(
                  opacity: _logoFade,
                  child: Center(child: MsLogo(height: 44)),
                ),
                const SizedBox(height: 40),

                // ── Header + Form (animated slide+fade) ────
                SlideTransition(
                  position: _formSlide,
                  child: FadeTransition(
                    opacity: _formFade,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to your MediShare account',
                          style: TextStyle(
                            fontSize: 14,
                            color: context.textSecondaryColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Mode Toggle: Email vs Phone OTP ──
                        Container(
                          height: 48,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.isDarkMode ? AppColors.dark2 : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: context.isDarkMode ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _isPhoneMode = false),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: !_isPhoneMode
                                          ? (context.isDarkMode ? context.cardBg : Colors.white)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: !_isPhoneMode
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withAlpha(15),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.email_outlined,
                                            size: 16,
                                            color: !_isPhoneMode ? AppColors.primary : context.textSecondaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Email',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: !_isPhoneMode ? FontWeight.w700 : FontWeight.w500,
                                              color: !_isPhoneMode ? context.textPrimaryColor : context.textSecondaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _isPhoneMode = true),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _isPhoneMode
                                          ? (context.isDarkMode ? context.cardBg : Colors.white)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: _isPhoneMode
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withAlpha(15),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.phone_android_rounded,
                                            size: 16,
                                            color: _isPhoneMode ? AppColors.primary : context.textSecondaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Phone OTP',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: _isPhoneMode ? FontWeight.w700 : FontWeight.w500,
                                              color: _isPhoneMode ? context.textPrimaryColor : context.textSecondaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        if (!_isPhoneMode) ...[
                          // ── Email ──────────────────────────
                          MsTextField(
                            label: 'Email Address',
                            hint: 'you@example.com',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            errorText: _emailError,
                            textInputAction: TextInputAction.next,
                            autofocus: true,
                            onChanged: (_) {
                              if (_emailError != null) {
                                setState(() => _emailError = null);
                              }
                            },
                          ),
                          const SizedBox(height: 20),

                          // ── Password ───────────────────────
                          MsTextField(
                            label: 'Password',
                            hint: 'Enter your password',
                            controller: _passCtrl,
                            isPassword: true,
                            prefixIcon: Icons.lock_outline,
                            errorText: _passError,
                            textInputAction: TextInputAction.done,
                            onChanged: (_) {
                              if (_passError != null) {
                                setState(() => _passError = null);
                              }
                            },
                            onSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 12),

                          // ── Forgot Password ─────────────────
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                AppPageTransitions.slideRight(
                                    const ForgotPasswordScreen()),
                              ),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Login Button ────────────────────
                          MsButton(
                            label: 'Sign In',
                            onPressed: isLoading ? null : _submit,
                            isLoading: isLoading,
                            icon: Icons.login_rounded,
                          ),
                        ] else ...[
                          // ── Phone Input ────────────────────
                          MsTextField(
                            label: 'Mobile Number',
                            hint: '98765 43210',
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_outlined,
                            errorText: _phoneError,
                            textInputAction: TextInputAction.done,
                            onChanged: (_) {
                              if (_phoneError != null) {
                                setState(() => _phoneError = null);
                              }
                            },
                            onSubmitted: (_) => _handleSendOtp(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.verified_user_outlined, size: 16, color: context.textSecondaryColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'A 6-digit OTP will be sent to your phone via SMS.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          MsButton(
                            label: 'Send OTP',
                            onPressed: _isSendingOtp ? null : _handleSendOtp,
                            isLoading: _isSendingOtp,
                            icon: Icons.sms_outlined,
                          ),
                        ],
                        const SizedBox(height: 20),

                        // ── OR Divider ──────────────────────
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: context.textSecondaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Register Link ───────────────────
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                AppPageTransitions.slideRight(
                                    const RegisterScreen()),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(
                                  color: context.textSecondaryColor,
                                  fontSize: 14,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'Register →',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
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