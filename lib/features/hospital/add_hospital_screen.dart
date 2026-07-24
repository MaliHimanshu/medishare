import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/hospital_provider.dart';
import '../../services/image_upload_service.dart';

class AddHospitalScreen extends StatefulWidget {
  const AddHospitalScreen({super.key});

  @override
  State<AddHospitalScreen> createState() => _AddHospitalScreenState();
}

class _AddHospitalScreenState extends State<AddHospitalScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _imageFile;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
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
              content: Text('Hospital logo selected! Will upload when saved.'),
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
                'Upload Hospital Logo',
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

  Future<void> _submitHospital() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final provider = context.read<HospitalProvider>();

    String imageUrl = '';
    if (_imageFile != null) {
      setState(() => _isUploadingImage = true);
      try {
        imageUrl = await ImageUploadService.instance.uploadImage(_imageFile!);
      } catch (e) {
        setState(() => _isUploadingImage = false);
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Logo upload failed: ${e.toString().replaceAll('Exception: ', '')}'),
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

    final success = await provider.addHospital(
      hospitalName: _nameController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      website: _websiteController.text.trim(),
      description: _descriptionController.text.trim(),
      contactPerson: _contactPersonController.text.trim(),
      image: imageUrl,
    );

    if (mounted) {
      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Hospital added successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        navigator.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage.isNotEmpty
                ? provider.errorMessage
                : 'Failed to add hospital.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HospitalProvider>();
    final isLoading = provider.isLoading || _isUploadingImage;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Add Hospital'),
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
                // Logo Upload Avatar
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _showImagePickerSheet,
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: _imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(48),
                                  child: Image.file(
                                    _imageFile!,
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.local_hospital_outlined,
                                  size: 44,
                                  color: AppColors.primary,
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

                const SizedBox(height: 24),

                // Hospital Name
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Hospital Name *',
                    labelStyle: TextStyle(color: context.textSecondaryColor),
                    prefixIcon: const Icon(Icons.local_hospital_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: context.inputBg,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Hospital name is required';
                    if (val.trim().length < 3) return 'Name must be at least 3 characters';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Contact Person
                TextFormField(
                  controller: _contactPersonController,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Contact Person',
                    labelStyle: TextStyle(color: context.textSecondaryColor),
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: context.inputBg,
                  ),
                ),

                const SizedBox(height: 16),

                // Phone & Email
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Phone (10 digits) *',
                    labelStyle: TextStyle(color: context.textSecondaryColor),
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: context.inputBg,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Phone is required';
                    if (!RegExp(r'^[0-9]{10}$').hasMatch(val.trim())) {
                      return 'Enter valid 10 digit phone';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Email Address *',
                    labelStyle: TextStyle(color: context.textSecondaryColor),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: context.inputBg,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Address
                TextFormField(
                  controller: _addressController,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Address *',
                    labelStyle: TextStyle(color: context.textSecondaryColor),
                    prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: context.inputBg,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Address is required';
                    if (val.trim().length < 5) return 'Address must be at least 5 characters';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // City, State, Pincode Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        style: TextStyle(color: context.textPrimaryColor),
                        decoration: InputDecoration(
                          labelText: 'City *',
                          labelStyle: TextStyle(color: context.textSecondaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          filled: true,
                          fillColor: context.inputBg,
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'City required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _stateController,
                        style: TextStyle(color: context.textPrimaryColor),
                        decoration: InputDecoration(
                          labelText: 'State *',
                          labelStyle: TextStyle(color: context.textSecondaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          filled: true,
                          fillColor: context.inputBg,
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'State required' : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Pincode (6 digits) *',
                    labelStyle: TextStyle(color: context.textSecondaryColor),
                    prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: context.inputBg,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Pincode is required';
                    if (!RegExp(r'^[0-9]{6}$').hasMatch(val.trim())) {
                      return 'Enter valid 6-digit pincode';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Website
                TextFormField(
                  controller: _websiteController,
                  keyboardType: TextInputType.url,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Website (Optional)',
                    labelStyle: TextStyle(color: context.textSecondaryColor),
                    prefixIcon: const Icon(Icons.language_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: context.inputBg,
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: TextStyle(color: context.textSecondaryColor),
                    prefixIcon: const Icon(Icons.description_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: context.inputBg,
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : _submitHospital,
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.add_business_outlined),
                    label: Text(
                      _isUploadingImage
                          ? 'Uploading Logo...'
                          : provider.isLoading
                              ? 'Saving Hospital...'
                              : 'Add Hospital',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
