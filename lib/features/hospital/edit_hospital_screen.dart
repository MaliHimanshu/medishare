import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_colors.dart';
import '../../models/hospital_model.dart';
import '../../providers/hospital_provider.dart';
import '../../shared/widgets/ms_image.dart';

class EditHospitalScreen extends StatefulWidget {
  final HospitalModel hospital;

  const EditHospitalScreen({
    super.key,
    required this.hospital,
  });

  @override
  State<EditHospitalScreen> createState() => _EditHospitalScreenState();
}

class _EditHospitalScreenState extends State<EditHospitalScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _contactPersonController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _websiteController;
  late TextEditingController _descriptionController;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.hospital.hospitalName);
    _contactPersonController = TextEditingController(text: widget.hospital.contactPerson);
    _emailController = TextEditingController(text: widget.hospital.email);
    _phoneController = TextEditingController(text: widget.hospital.phone);
    _addressController = TextEditingController(text: widget.hospital.address);
    _cityController = TextEditingController(text: widget.hospital.city);
    _stateController = TextEditingController(text: widget.hospital.state);
    _pincodeController = TextEditingController(text: widget.hospital.pincode);
    _websiteController = TextEditingController(text: widget.hospital.website);
    _descriptionController = TextEditingController(text: widget.hospital.description);
  }

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
                'Change Hospital Logo',
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

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final provider = context.read<HospitalProvider>();

    String imageUrl = widget.hospital.image;
    if (_imageFile != null) {
      imageUrl = "https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=600&q=80";
    }

    final success = await provider.updateHospital(
      widget.hospital.id,
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
            content: Text('Hospital details updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        navigator.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage.isNotEmpty
                ? provider.errorMessage
                : 'Failed to update hospital.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HospitalProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Hospital'),
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
              // Logo Avatar Edit
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showImagePickerSheet,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(48),
                        child: _imageFile != null
                            ? Image.file(
                                _imageFile!,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                              )
                            : MsImage(
                                imageUrl: widget.hospital.image,
                                width: 96,
                                height: 96,
                                borderRadius: BorderRadius.circular(48),
                                placeholderIcon: Icons.local_hospital_outlined,
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
                          Icons.edit,
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
                decoration: InputDecoration(
                  labelText: 'Hospital Name *',
                  prefixIcon: const Icon(Icons.local_hospital_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: AppColors.surface,
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
                decoration: InputDecoration(
                  labelText: 'Contact Person',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),

              const SizedBox(height: 16),

              // Phone & Email
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Phone is required' : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address *',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Email is required' : null,
              ),

              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address *',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Address is required' : null,
              ),

              const SizedBox(height: 16),

              // City, State, Pincode
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'City *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'City required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: InputDecoration(
                        labelText: 'State *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        filled: true,
                        fillColor: AppColors.surface,
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
                decoration: InputDecoration(
                  labelText: 'Pincode *',
                  prefixIcon: const Icon(Icons.pin_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Pincode required' : null,
              ),

              const SizedBox(height: 16),

              // Website
              TextFormField(
                controller: _websiteController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Website (Optional)',
                  prefixIcon: const Icon(Icons.language_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: const Icon(Icons.description_outlined),
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
                  onPressed: provider.isLoading ? null : _submitUpdate,
                  icon: provider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    provider.isLoading ? 'Updating...' : 'Save Changes',
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
    );
  }
}
