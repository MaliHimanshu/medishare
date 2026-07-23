import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/ms_image.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<bool> _checkPermission(ImageSource source) async {
    if (Platform.isAndroid) {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        return status.isGranted;
      }
      return true;
    } else if (Platform.isIOS) {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        return status.isGranted;
      } else {
        final status = await Permission.photos.request();
        return status.isGranted || status.isLimited;
      }
    }
    return true;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final hasPermission = await _checkPermission(source);
      if (!hasPermission) return;

      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (_) {}
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Change Profile Photo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final profileProvider = context.read<ProfileProvider>();
    final authProvider = context.read<AuthProvider>();

    String imageUrl = widget.user.profileImage ?? '';
    if (_imageFile != null) {
      imageUrl = "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=600&q=80";
    }

    final success = await profileProvider.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      profileImage: imageUrl,
    );

    if (mounted) {
      if (success) {
        authProvider.checkAuthStatus(); // Refresh global auth state
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        navigator.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(profileProvider.errorMessage.isNotEmpty
                ? profileProvider.errorMessage
                : 'Failed to update profile.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Edit Header
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showImagePickerSheet,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: _imageFile != null
                            ? Image.file(
                                _imageFile!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              )
                            : MsImage(
                                imageUrl: widget.user.profileImage,
                                width: 100,
                                height: 100,
                                borderRadius: BorderRadius.circular(50),
                                placeholderIcon: Icons.person,
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Full Name Input
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Name is required';
                  if (val.trim().length < 3) return 'Name must be at least 3 characters';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email Input (READ-ONLY)
              TextFormField(
                initialValue: widget.user.email,
                readOnly: true,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email Address (Read-only)',
                  prefixIcon: const Icon(Icons.email_outlined),
                  suffixIcon: const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),

              const SizedBox(height: 16),

              // Phone Input
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (val) {
                  if (val != null && val.isNotEmpty && !RegExp(r'^[0-9]{10}$').hasMatch(val.trim())) {
                    return 'Enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Address Input
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Address / Location',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),

              const SizedBox(height: 32),

              // Save Changes Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: profileProvider.isLoading ? null : _saveProfile,
                  icon: profileProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    profileProvider.isLoading ? 'Saving Changes...' : 'Save Profile',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}