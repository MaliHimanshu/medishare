import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_page_transitions.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/ms_button.dart';
import '../../shared/widgets/ms_logo.dart';
import '../../shared/widgets/ms_text_field.dart';
import '../otp/otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();

  String _selectedCountryCode = '+91';
  String? _inputError;
  bool _isSending = false;

  final List<String> _countryCodes = ['+91', '+1', '+44', '+61', '+971', '+81'];

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
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
    if (_isSending) return;

    setState(() => _inputError = null);

    final err = _validatePhone(_phoneCtrl.text);
    if (err != null) {
      setState(() => _inputError = err);
      return;
    }

    setState(() => _isSending = true);

    try {
      final auth = context.read<AuthProvider>();
      String cleanPhone = _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
      if (cleanPhone.startsWith('91') && cleanPhone.length > 10) {
        cleanPhone = cleanPhone.substring(2);
      }
      while (cleanPhone.startsWith('0')) {
        cleanPhone = cleanPhone.substring(1);
      }
      final rawTarget = '+91$cleanPhone';

      final success = await auth.sendForgotPasswordOtp(rawTarget, 'phone');

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('OTP sent to your phone via SMS 📲'),
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
              type: 'phone',
              isForgotPassword: true,
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {

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
                  'Enter your registered phone number to receive a 6-digit SMS verification code to reset your password.',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textSecondaryColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

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

                const SizedBox(height: 36),

                // ── Send OTP Button ──────────────────────────
                MsButton(
                  label: _isSending ? 'Sending OTP...' : 'Send OTP',
                  onPressed: _isSending ? null : _submit,
                  isLoading: _isSending,
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