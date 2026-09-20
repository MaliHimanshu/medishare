import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_page_transitions.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/ms_button.dart';
import '../../shared/widgets/ms_logo.dart';
import '../../shared/widgets/ms_text_field.dart';
import '../auth/login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? target;
  final String? type;
  final String? resetToken;

  const ResetPasswordScreen({
    super.key,
    this.target,
    this.type,
    this.resetToken,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  String? _newPassError;
  String? _confirmPassError;

  @override
  void initState() {
    super.initState();
    // Security check: Never allow user to directly open without a valid resetToken
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.resetToken == null || widget.resetToken!.isEmpty) {
        _showUnauthorizedAccessDialog();
      }
    });
  }

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _showUnauthorizedAccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.error),
            SizedBox(width: 8),
            Text('Verification Required'),
          ],
        ),
        content: const Text(
          'Password reset requires completing OTP verification first. Please request a password reset from the login screen.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                AppPageTransitions.slideRight(const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Go to Login', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != _newPassCtrl.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submitReset() async {
    setState(() {
      _newPassError = _validatePassword(_newPassCtrl.text);
      _confirmPassError = _validateConfirmPassword(_confirmPassCtrl.text);
    });

    if (_newPassError != null || _confirmPassError != null) return;

    if (widget.target == null || widget.type == null || widget.resetToken == null) {
      _showUnauthorizedAccessDialog();
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.resetPassword(
      widget.target!,
      widget.type!,
      widget.resetToken!,
      _newPassCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Password reset failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 72,
                  width: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Password Reset Successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your password has been updated. You can now sign in with your new password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textSecondaryColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                MsButton(
                  label: 'Back to Login',
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushAndRemoveUntil(
                      context,
                      AppPageTransitions.slideRight(const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            AppPageTransitions.slideRight(const LoginScreen()),
            (route) => false,
          ),
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

                Center(
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.key_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Create New Password',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your new password must be at least 8 characters long.',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textSecondaryColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                // ── New Password Field ───────────────────────
                MsTextField(
                  label: 'New Password',
                  hint: 'Enter your new password',
                  controller: _newPassCtrl,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline,
                  errorText: _newPassError,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (_newPassError != null) setState(() => _newPassError = null);
                  },
                ),
                const SizedBox(height: 20),

                // ── Confirm Password Field ────────────────────
                MsTextField(
                  label: 'Confirm Password',
                  hint: 'Re-enter your new password',
                  controller: _confirmPassCtrl,
                  isPassword: true,
                  prefixIcon: Icons.lock_reset_outlined,
                  errorText: _confirmPassError,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (_confirmPassError != null) setState(() => _confirmPassError = null);
                  },
                  onSubmitted: (_) => _submitReset(),
                ),

                const SizedBox(height: 36),

                // ── Reset Password Button ────────────────────
                MsButton(
                  label: 'Reset Password',
                  onPressed: isLoading ? null : _submitReset,
                  isLoading: isLoading,
                  icon: Icons.check_circle_outline_rounded,
                ),

                const SizedBox(height: 24),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        AppPageTransitions.slideRight(const LoginScreen()),
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Back to Login',
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