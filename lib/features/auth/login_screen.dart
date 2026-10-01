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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  String? _identifierError;
  String? _passError;

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

    _formSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
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
    _identifierCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  String? _validateIdentifier(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Email or phone number is required';
    }
    final trimmed = v.trim();
    if (trimmed.contains('@')) {
      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed)) {
        return 'Enter a valid email address';
      }
    } else {
      final cleanDigits = trimmed.replaceAll(RegExp(r'\D'), '');
      if (cleanDigits.length < 10) {
        return 'Enter a valid 10-digit mobile number or email address';
      }
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
      _identifierError = _validateIdentifier(_identifierCtrl.text);
      _passError = _validatePassword(_passCtrl.text);
    });

    if (_identifierError != null || _passError != null) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _identifierCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Welcome back, ${auth.user?.name.split(' ').first ?? 'there'}! 👋',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.isLoading;

    return Scaffold(
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
                  child: const Center(child: MsLogo(height: 44)),
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
                        const SizedBox(height: 32),

                        // ── Email / Phone Field ────────────
                        MsTextField(
                          label: 'Email or Mobile Number',
                          hint: 'you@example.com or 9876543210',
                          controller: _identifierCtrl,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.person_outline_rounded,
                          errorText: _identifierError,
                          textInputAction: TextInputAction.next,
                          autofocus: false,
                          onChanged: (_) {
                            if (_identifierError != null) {
                              setState(() => _identifierError = null);
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
                                const ForgotPasswordScreen(),
                              ),
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
                        const SizedBox(height: 28),

                        // ── Register Link ───────────────────
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                AppPageTransitions.slideRight(
                                  const RegisterScreen(),
                                ),
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
