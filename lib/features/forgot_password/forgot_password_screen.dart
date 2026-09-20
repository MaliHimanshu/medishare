import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_page_transitions.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/ms_button.dart';
import '../../shared/widgets/ms_logo.dart';
import '../../shared/widgets/ms_text_field.dart';
import '../otp/otp_screen.dart';

enum RecoveryType { email, phone }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  RecoveryType _selectedType = RecoveryType.email;
  String _selectedCountryCode = '+91';
  String? _inputError;

  final List<String> _countryCodes = ['+91', '+1', '+44', '+61', '+971', '+81'];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email address is required';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    final cleanPhone = v.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length < 7 || cleanPhone.length > 15) {
      return 'Enter a valid phone number (7-15 digits)';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() => _inputError = null);

    if (_selectedType == RecoveryType.email) {
      final err = _validateEmail(_emailCtrl.text);
      if (err != null) {
        setState(() => _inputError = err);
        return;
      }
    } else {
      final err = _validatePhone(_phoneCtrl.text);
      if (err != null) {
        setState(() => _inputError = err);
        return;
      }
    }

    final auth = context.read<AuthProvider>();
    final typeStr = _selectedType == RecoveryType.email ? 'email' : 'phone';
    final rawTarget = _selectedType == RecoveryType.email
        ? _emailCtrl.text.trim()
        : '$_selectedCountryCode${_phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '')}';

    final success = await auth.sendForgotPasswordOtp(rawTarget, typeStr);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification code sent to your ${_selectedType == RecoveryType.email ? 'email' : 'phone'}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.push(
        context,
        AppPageTransitions.slideRight(
          OtpScreen(
            target: rawTarget,
            type: typeStr,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to send verification code'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Center(child: MsLogo(height: 40)),
                const SizedBox(height: 32),

                // Lock reset icon container
                Center(
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 42,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select how you would like to receive your 6-digit verification code to reset your password.',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textSecondaryColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Segmented Control (Tabs) ─────────────────
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? Colors.grey.shade900 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = RecoveryType.email;
                              _inputError = null;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedType == RecoveryType.email
                                  ? (context.isDarkMode ? AppColors.dark2 : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _selectedType == RecoveryType.email
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(10),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 18,
                                  color: _selectedType == RecoveryType.email
                                      ? AppColors.primary
                                      : context.textSecondaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Email',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: _selectedType == RecoveryType.email
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _selectedType == RecoveryType.email
                                        ? context.textPrimaryColor
                                        : context.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = RecoveryType.phone;
                              _inputError = null;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedType == RecoveryType.phone
                                  ? (context.isDarkMode ? AppColors.dark2 : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _selectedType == RecoveryType.phone
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(10),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone_android_outlined,
                                  size: 18,
                                  color: _selectedType == RecoveryType.phone
                                      ? AppColors.primary
                                      : context.textSecondaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Phone Number',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: _selectedType == RecoveryType.phone
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _selectedType == RecoveryType.phone
                                        ? context.textPrimaryColor
                                        : context.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Input Fields ─────────────────────────────
                if (_selectedType == RecoveryType.email) ...[
                  MsTextField(
                    label: 'Email Address',
                    hint: 'Enter your registered email',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    errorText: _inputError,
                    onChanged: (_) {
                      if (_inputError != null) setState(() => _inputError = null);
                    },
                    onSubmitted: (_) => _submit(),
                  ),
                ] else ...[
                  Text(
                    'Phone Number',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Country Code Picker
                      Container(
                        height: 54,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: context.isDarkMode ? AppColors.dark2 : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: context.isDarkMode ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCountryCode,
                            icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                            items: _countryCodes.map((code) {
                              return DropdownMenuItem<String>(
                                value: code,
                                child: Text(
                                  code,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCountryCode = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Phone Input Box
                      Expanded(
                        child: MsTextField(
                          label: 'Phone Number',
                          hint: '9876543210',
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined,
                          errorText: _inputError,
                          onChanged: (_) {
                            if (_inputError != null) setState(() => _inputError = null);
                          },
                          onSubmitted: (_) => _submit(),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 36),

                // ── Send OTP Button ──────────────────────────
                MsButton(
                  label: 'Send OTP',
                  onPressed: isLoading ? null : _submit,
                  isLoading: isLoading,
                  icon: Icons.send_rounded,
                ),

                const SizedBox(height: 24),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      '← Back to Sign In',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}