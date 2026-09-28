import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_page_transitions.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/ms_button.dart';
import '../../shared/widgets/ms_logo.dart';
import '../../shared/widgets/ms_text_field.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';
import '../home/home_screen.dart';

// Role option data
class _Role {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;

  const _Role({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

const _roles = [
  _Role(
    value: 'DONOR',
    title: 'Donor',
    subtitle: 'Donate or rent medical equipment',
    icon: Icons.volunteer_activism_rounded,
  ),
  _Role(
    value: 'NGO',
    title: 'NGO',
    subtitle: 'Manage and distribute equipment',
    icon: Icons.diversity_3_rounded,
  ),
  _Role(
    value: 'HOSPITAL',
    title: 'Hospital',
    subtitle: 'Request and manage equipment',
    icon: Icons.local_hospital_rounded,
  ),
  _Role(
    value: 'RECIPIENT',
    title: 'Recipient',
    subtitle: 'Request equipment for personal use',
    icon: Icons.personal_injury_rounded,
  ),
];

class RegisterScreen extends StatefulWidget {
  final String? initialPhone;
  final bool isPhoneVerified;

  const RegisterScreen({
    super.key,
    this.initialPhone,
    this.isPhoneVerified = false,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl          = TextEditingController();
  final _emailCtrl         = TextEditingController();
  final _phoneCtrl         = TextEditingController();
  final _addressCtrl       = TextEditingController();
  final _orgNameCtrl       = TextEditingController();
  final _regNumberCtrl     = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _preferenceCtrl    = TextEditingController();
  final _passCtrl          = TextEditingController();
  final _confirmCtrl       = TextEditingController();

  String _selectedRole = 'DONOR';
  bool _phoneVerified = false;

  // Field errors
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _phoneVerified = widget.isPhoneVerified;
    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      final clean = widget.initialPhone!.replaceAll(RegExp(r'\D'), '');
      _phoneCtrl.text = clean.length >= 10 ? clean.substring(clean.length - 10) : clean;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _orgNameCtrl.dispose();
    _regNumberCtrl.dispose();
    _contactPersonCtrl.dispose();
    _preferenceCtrl.dispose();
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
      final cleanDigits = phone.replaceAll(RegExp(r'\D'), '');
      if (phone.isEmpty) {
        _phoneError = 'Mobile number is required';
      } else if (cleanDigits.length < 10 || cleanDigits.length > 13) {
        _phoneError = 'Enter a valid 10-digit mobile number';
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

    String cleanDigits = _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
    if (cleanDigits.startsWith('91') && cleanDigits.length > 10) {
      cleanDigits = cleanDigits.substring(2);
    }
    while (cleanDigits.startsWith('0')) {
      cleanDigits = cleanDigits.substring(1);
    }
    final normalizedPhone = '+91$cleanDigits';

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name:                _nameCtrl.text.trim(),
      email:               _emailCtrl.text.trim(),
      password:            _passCtrl.text,
      role:                _selectedRole,
      phone:               normalizedPhone,
      address:             _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      organizationName:   _orgNameCtrl.text.trim().isEmpty ? null : _orgNameCtrl.text.trim(),
      registrationNumber: _regNumberCtrl.text.trim().isEmpty ? null : _regNumberCtrl.text.trim(),
      contactPerson:      _contactPersonCtrl.text.trim().isEmpty ? null : _contactPersonCtrl.text.trim(),
      equipmentPreference:_preferenceCtrl.text.trim().isEmpty ? null : _preferenceCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      if (_phoneVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account created successfully! 🎉'),
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
        if (auth.errorMessage != null && auth.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(auth.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Account created! Verification code sent 📲'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        Navigator.pushReplacement(
          context,
          AppPageTransitions.slideRight(
            OtpVerificationScreen(
              phone: normalizedPhone,
              initialErrorMessage: auth.errorMessage,
            ),
          ),
        );
      }
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
              Text(
                'I am joining as',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 540;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _roles.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 4 : 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: isWide ? 1.0 : 1.12,
                    ),
                    itemBuilder: (context, index) {
                      final role = _roles[index];
                      final isSelected = _selectedRole == role.value;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedRole = role.value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withAlpha(20)
                                : (context.isDarkMode
                                    ? context.cardBg
                                    : AppColors.surface),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : context.borderColor,
                              width: isSelected ? 2.0 : 1.2,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? AppColors.primary.withAlpha(25)
                                    : Colors.black.withAlpha(
                                        context.isDarkMode ? 15 : 4,
                                      ),
                                blurRadius: isSelected ? 8 : 4,
                                offset: Offset(0, isSelected ? 2 : 1),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withAlpha(35)
                                      : (context.isDarkMode
                                          ? Colors.white10
                                          : AppColors.surface2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  role.icon,
                                  size: 20,
                                  color: isSelected
                                      ? AppColors.primary
                                      : context.textSecondaryColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                role.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.primary
                                      : context.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                role.subtitle,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  height: 1.2,
                                  color: isSelected
                                      ? AppColors.primary.withAlpha(220)
                                      : context.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
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

              // ── Phone Field ──────────────────────────
              MsTextField(
                label: 'Mobile Number *',
                hint: '10-digit mobile number',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                errorText: _phoneError,
                textInputAction: TextInputAction.next,
                onChanged: (_) {
                  if (_phoneError != null) setState(() => _phoneError = null);
                },
              ),
              const SizedBox(height: 16),

              // ── City / Address Field ──────────────────
              MsTextField(
                label: _selectedRole == 'DONOR'
                    ? 'Pickup Address / Preferred Location'
                    : _selectedRole == 'NGO'
                        ? 'NGO Office Address'
                        : _selectedRole == 'HOSPITAL'
                            ? 'Hospital / Clinic Address'
                            : 'Delivery Address / Location (Optional)',
                hint: 'e.g. Ahmedabad, Gujarat',
                controller: _addressCtrl,
                prefixIcon: Icons.location_on_outlined,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // ── Role Specific Registration Fields ─────
              if (_selectedRole == 'NGO' || _selectedRole == 'HOSPITAL') ...[
                MsTextField(
                  label: _selectedRole == 'NGO'
                      ? 'NGO / Organization Name'
                      : 'Hospital Name',
                  hint: _selectedRole == 'NGO'
                      ? 'e.g. Hope Health Trust'
                      : 'e.g. City Care Hospital',
                  controller: _orgNameCtrl,
                  prefixIcon: Icons.business_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                MsTextField(
                  label: _selectedRole == 'NGO'
                      ? 'NGO Registration Number'
                      : 'Hospital License / Reg No',
                  hint: 'e.g. REG-2024-8891',
                  controller: _regNumberCtrl,
                  prefixIcon: Icons.badge_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                MsTextField(
                  label: 'Contact Person / Coordinator',
                  hint: 'e.g. Dr. Rajesh Sharma',
                  controller: _contactPersonCtrl,
                  prefixIcon: Icons.assignment_ind_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
              ] else if (_selectedRole == 'RECIPIENT') ...[
                MsTextField(
                  label: 'Equipment Needed / Preference (Optional)',
                  hint: 'e.g. Wheelchair, Oxygen Concentrator',
                  controller: _preferenceCtrl,
                  prefixIcon: Icons.medical_services_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
              ],

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