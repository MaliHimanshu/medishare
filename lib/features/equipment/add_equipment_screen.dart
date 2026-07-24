import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

// Providers
import '../../providers/equipment_provider.dart';

// Services
import '../../services/image_upload_service.dart';

// Shared Constants & Extensions
import '../../core/constants/app_colors.dart';

class AddEquipmentScreen extends StatefulWidget {
  const AddEquipmentScreen({super.key});

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String selectedCategory = "Mobility";
  String selectedCondition = "GOOD";

  final List<String> categories = [
    "Mobility",
    "Respiratory",
    "Critical Care",
    "Furniture",
    "Diagnostic",
    "Surgical",
    "Other",
  ];

  final List<String> conditions = [
    "NEW",
    "LIKE_NEW",
    "GOOD",
    "FAIR",
  ];

  bool _isSaving = false;
  bool _isUploadingImage = false;
  double _uploadProgress = 0.0;

  // Image upload state
  File? _imageFile;

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Image Selection Handler
  // ─────────────────────────────────────────────
  Future<void> _onPickImage(ImageSource source) async {
    try {
      final pickedFile = await ImageUploadService.instance.pickImage(source);
      if (pickedFile == null) return; // User cancelled or permission denied

      setState(() {
        _imageFile = pickedFile;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image selected! It will be uploaded on listing submission."),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not retrieve image: $e"),
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
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Upload Equipment Image",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text("Take Photo"),
                onTap: () {
                  Navigator.pop(ctx);
                  _onPickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(ctx);
                  _onPickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: Colors.grey),
                title: const Text("Cancel"),
                onTap: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Image removed."),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Submit Flow
  // ─────────────────────────────────────────────
  Future<void> submitEquipment() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<EquipmentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isSaving = true;
      _uploadProgress = 0.0;
    });

    String uploadedImageUrl = '';
    if (_imageFile != null) {
      setState(() => _isUploadingImage = true);
      try {
        uploadedImageUrl = await ImageUploadService.instance.uploadImage(
          _imageFile!,
          onProgress: (sent, total) {
            if (total > 0 && mounted) {
              setState(() {
                _uploadProgress = sent / total;
              });
            }
          },
        );
      } catch (e) {
        setState(() {
          _isSaving = false;
          _isUploadingImage = false;
        });
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text("Image upload failed: ${e.toString().replaceAll('Exception: ', '')}"),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      } finally {
        if (mounted) setState(() => _isUploadingImage = false);
      }
    }

    final success = await provider.addEquipment(
      name: _nameController.text.trim(),
      category: selectedCategory,
      condition: selectedCondition,
      quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
      manufacturer: _manufacturerController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      image: uploadedImageUrl,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Equipment Listing Created Successfully!"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
        navigator.pop(true);
      } else {
        final err = provider.errorMessage;
        messenger.showSnackBar(
          SnackBar(
            content: Text(err.isNotEmpty ? err : "Failed to create listing."),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final isDark = context.isDarkMode;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(color: context.textPrimaryColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: context.textSecondaryColor),
          prefixIcon: Icon(icon, color: AppColors.primary),
          filled: true,
          fillColor: context.inputBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("List Medical Equipment", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Circular Image Upload UI Section
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _showImagePickerSheet,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                              ),
                              child: _imageFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(55),
                                      child: Image.file(
                                        _imageFile!,
                                        fit: BoxFit.cover,
                                        width: 110,
                                        height: 110,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.camera_alt_outlined,
                                          size: 36,
                                          color: AppColors.primary,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "Add Photo",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          if (_imageFile != null)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _removeImage,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            )
                          else
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
                                  Icons.add,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Equipment Name
                    buildTextField(
                      controller: _nameController,
                      label: "Equipment Name *",
                      icon: Icons.medical_services_outlined,
                      validator: (val) => val == null || val.trim().isEmpty ? "Name is required" : null,
                    ),

                    // Category Dropdown
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        dropdownColor: context.cardBg,
                        style: TextStyle(color: context.textPrimaryColor),
                        decoration: InputDecoration(
                          labelText: "Category *",
                          labelStyle: TextStyle(color: context.textSecondaryColor),
                          prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primary),
                          filled: true,
                          fillColor: context.inputBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: context.borderColor, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: context.borderColor, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedCategory = value;
                            });
                          }
                        },
                      ),
                    ),

                    // Manufacturer
                    buildTextField(
                      controller: _manufacturerController,
                      label: "Manufacturer (Optional)",
                      icon: Icons.business_outlined,
                    ),

                    // Quantity
                    buildTextField(
                      controller: _quantityController,
                      label: "Quantity *",
                      icon: Icons.inventory_2_outlined,
                      keyboard: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return "Quantity is required";
                        final parsed = int.tryParse(val.trim());
                        if (parsed == null || parsed <= 0) return "Must be a valid positive number";
                        return null;
                      },
                    ),

                    // Condition Dropdown
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedCondition,
                        dropdownColor: context.cardBg,
                        style: TextStyle(color: context.textPrimaryColor),
                        decoration: InputDecoration(
                          labelText: "Condition *",
                          labelStyle: TextStyle(color: context.textSecondaryColor),
                          prefixIcon: const Icon(Icons.health_and_safety_outlined, color: AppColors.primary),
                          filled: true,
                          fillColor: context.inputBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: context.borderColor, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: context.borderColor, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        items: conditions.map((cond) {
                          return DropdownMenuItem(
                            value: cond,
                            child: Text(cond.replaceAll('_', ' ')),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedCondition = value;
                            });
                          }
                        },
                      ),
                    ),

                    // Location
                    buildTextField(
                      controller: _locationController,
                      label: "Location *",
                      icon: Icons.location_on_outlined,
                      validator: (val) => val == null || val.trim().isEmpty ? "Location is required" : null,
                    ),

                    // Description
                    buildTextField(
                      controller: _descriptionController,
                      label: "Description (Optional)",
                      icon: Icons.description_outlined,
                      maxLines: 4,
                    ),

                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _isSaving ? null : submitEquipment,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          _isSaving ? "Saving Listing..." : "Submit Listing",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            if (_isSaving)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppColors.primary),
                          const SizedBox(height: 18),
                          Text(
                            _isUploadingImage
                                ? "Uploading Image (${(_uploadProgress * 100).toInt()}%)..."
                                : "Submitting Equipment Listing...",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}