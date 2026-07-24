import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/image_upload_service.dart';
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
  bool _isUploadingImage = false;

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImageUploadService.instance.pickImage(source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New avatar selected! Will upload when profile is saved.'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
      setState(() => _isUploadingImage = true);
      try {
        imageUrl = await ImageUploadService.instance.uploadImage(_imageFile!);
      } catch (e) {
        setState(() => _isUploadingImage = false);
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Image upload failed: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      } finally {
        if (mounted) setState(() => _isUploadingImage = false);
      }
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
            behavior: SnackBarBehavior.floating,
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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final isLoading = profileProvider.isLoading || _isUploadingImage;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        backgroundColor: context.cardBg,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    labelStyle: TextStyle(color: context.textSecondaryColor),
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: context.inputBg,
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
                  style: TextStyle(color: context.textSecondaryColor),
                  decoration: InputDecoration(
                    labelText: 'Email Address (Read-only)',
                    labelStyle: TextStyle(color: context.textSecondaryColor),
                    prefixIcon: const Icon(Icons.email_outlined),
                    suffixIcon: const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.15),
                  ),
                ),

                const SizedBox(height: 16),

                // Phone Input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: context.textSecondaryColor),
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: context.inputBg,
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
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Address / Location',
                    labelStyle: TextStyle(color: context.textSecondaryColor),
                    prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: context.inputBg,
                  ),
                ),

                const SizedBox(height: 32),

                // Save Changes Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : _saveProfile,
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _isUploadingImage
                          ? 'Uploading Photo...'
                          : profileProvider.isLoading
                              ? 'Saving Changes...'
                              : 'Save Profile',
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
      ),
    );
  }
}