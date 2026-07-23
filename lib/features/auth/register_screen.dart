import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_page_transitions.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/ms_button.dart';
import '../../shared/widgets/ms_logo.dart';
import '../../shared/widgets/ms_text_field.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

// Role option data
class _Role {
  final String value;
  final String label;
  final String emoji;
  final String desc;
  final Color color;

  const _Role({
    required this.value,
    required this.label,
    required this.emoji,
    required this.desc,
    required this.color,
  });
}

const _roles = [
  _Role(
    value: 'DONOR',
    label: 'Donor',
    emoji: '🤲',
    desc: 'Donate equipment',
    color: AppColors.primary,
  ),
  _Role(
    value: 'NGO',
    label: 'NGO',
    emoji: '🏢',
    desc: 'Partner NGO',
    color: AppColors.accent,
  ),
  _Role(
    value: 'RECIPIENT',
    label: 'Hospital',
    emoji: '🏥',
    desc: 'Healthcare org',
    color: Color(0xFF7C3AED),
  ),
];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _selectedRole = 'DONOR';

  // Field errors
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passError;
  String? _confirmError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _nameError = _nameCtrl.text.trim().isEmpty ? 'Full name is required' : null;

      final email = _emailCtrl.text.trim();
      if (email.isEmpty) {
        _emailError = 'Email is required';
      } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
        _emailError = 'Enter a valid email address';
      } else {
        _emailError = null;
      }

      final phone = _phoneCtrl.text.trim();
      if (phone.isNotEmpty && phone.replaceAll(RegExp(r'\D'), '').length != 10) {
        _phoneError = 'Enter a valid 10-digit number';
      } else {
        _phoneError = null;
      }

      final pass = _passCtrl.text;
      if (pass.isEmpty) {
        _passError = 'Password is required';
      } else if (pass.length < 8) {
        _passError = 'At least 8 characters required';
      } else if (!RegExp(r'(?=.*[A-Z])(?=.*\d)').hasMatch(pass)) {
        _passError = 'Must include uppercase letter and number';
      } else {
        _passError = null;
      }

      _confirmError = (_confirmCtrl.text != _passCtrl.text)
          ? 'Passwords do not match'
          : null;
    });

    return _nameError == null &&
        _emailError == null &&
        _phoneError == null &&
        _passError == null &&
        _confirmError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name:     _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
      role:     _selectedRole,
      phone:    _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      address:  _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Account created! Welcome to MediShare 🎉'),
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
          content: Text(auth.errorMessage ?? 'Registration failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  int get _passwordStrength {
    final p = _passCtrl.text;
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
    return score;
  }

  Color get _strengthColor {
    switch (_passwordStrength) {
      case 1: return AppColors.error;
      case 2: return AppColors.warning;
      case 3: return AppColors.info;
      case 4: return AppColors.success;
      default: return AppColors.border;
    }
  }

  String get _strengthLabel {
    switch (_passwordStrength) {
      case 1: return 'Weak';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Strong';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthProvider>();
    final isLoading = auth.isLoading;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.surfaceBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const MsLogo(height: 38),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Header ────────────────────────────────
              Text(
                'Create account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    AppPageTransitions.slideRight(const LoginScreen()),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: TextStyle(color: context.textSecondaryColor, fontSize: 13),
                    children: const [
                      TextSpan(
                        text: 'Sign in →',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Role Selector ─────────────────────────
              const Text(
                'I am joining as',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: _roles.map((role) {
                  final isSelected = _selectedRole == role.value;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRole = role.value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? role.color.withAlpha(20)
                              : AppColors.surface,
                          border: Border.all(
                            color: isSelected ? role.color : AppColors.border,
                            width: isSelected ? 2 : 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(role.emoji, style: const TextStyle(fontSize: 24)),
                            const SizedBox(height: 6),
                            Text(
                              role.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? role.color : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              role.desc,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // ── Name & Email ──────────────────────────
              MsTextField(
                label: 'Full Name',
                hint: 'John Doe',
                controller: _nameCtrl,
                prefixIcon: Icons.person_outline,
                errorText: _nameError,
                textInputAction: TextInputAction.next,
                autofocus: true,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
              ),
              const SizedBox(height: 16),

              MsTextField(
                label: 'Email Address',
                hint: 'you@example.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                errorText: _emailError,
                textInputAction: TextInputAction.next,
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
              ),
              const SizedBox(height: 16),

              // ── Phone & Address ───────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: MsTextField(
                      label: 'Phone (Optional)',
                      hint: '9876543210',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      errorText: _phoneError,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        if (_phoneError != null) setState(() => _phoneError = null);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MsTextField(
                      label: 'City (Optional)',
                      hint: 'Ahmedabad',
                      controller: _addressCtrl,
                      prefixIcon: Icons.location_on_outlined,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Password ──────────────────────────────
              MsTextField(
                label: 'Password',
                hint: 'Min 8 chars, uppercase + number',
                controller: _passCtrl,
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                errorText: _passError,
                textInputAction: TextInputAction.next,
                onChanged: (_) {
                  if (_passError != null) setState(() => _passError = null);
                  setState(() {}); // update strength indicator
                },
              ),

              // Password strength bar
              if (_passCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    ...List.generate(4, (i) {
                      return Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 4),
                          height: 4,
                          decoration: BoxDecoration(
                            color: i < _passwordStrength
                                ? _strengthColor
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      _strengthLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _strengthColor,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              MsTextField(
                label: 'Confirm Password',
                hint: 'Repeat your password',
                controller: _confirmCtrl,
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                errorText: _confirmError,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_confirmError != null) setState(() => _confirmError = null);
                },
                onSubmitted: (_) => _submit(),
              ),

              const SizedBox(height: 32),

              // ── Submit ────────────────────────────────
              MsButton(
                label: 'Create Free Account',
                onPressed: isLoading ? null : _submit,
                isLoading: isLoading,
                icon: Icons.person_add_outlined,
              ),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  'By registering, you agree to our Terms & Privacy Policy',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}