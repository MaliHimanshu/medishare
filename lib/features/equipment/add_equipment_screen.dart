import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

// Providers
import '../../providers/equipment_provider.dart';

// Shared Constants
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

  // Image upload states
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

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
  // Permissions & Dialog Helper
  // ─────────────────────────────────────────────
  Future<bool> _checkPermission(ImageSource source) async {
    if (Platform.isAndroid) {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (status.isGranted) return true;
        _showPermissionDialog("Camera");
        return false;
      }
      // On Android, Photo Picker handles gallery permission natively without manual storage checks
      return true;
    } else if (Platform.isIOS) {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (status.isGranted) return true;
        _showPermissionDialog("Camera");
        return false;
      } else {
        final status = await Permission.photos.request();
        if (status.isGranted || status.isLimited) return true;
        _showPermissionDialog("Photos/Gallery");
        return false;
      }
    }
    return true;
  }

  void _showPermissionDialog(String serviceName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("$serviceName Permission Required"),
        content: Text("MediShare needs access to your $serviceName to attach equipment photos. Please grant permission in the App Settings."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Image Selection Handler
  // ─────────────────────────────────────────────
  Future<void> _onPickImage(ImageSource source) async {
    try {
      final hasPermission = await _checkPermission(source);
      if (!hasPermission) return;

      // Natively compresses to 1024px maximum dimension with 85% JPEG quality at source
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return; // User cancelled

      setState(() {
        _imageFile = File(pickedFile.path);
      });
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
  // Isolated Image Upload Logic
  // ─────────────────────────────────────────────
  /// Uploads image file using multipart/form-data with Dio if supported,
  /// otherwise returns mock URL for presentation storage.
  Future<String> _uploadImage(File file) async {
    try {
      // Stubbed multipart file upload code for future API connection:
      // final formData = FormData.fromMap({
      //   'file': await MultipartFile.fromFile(file.path, filename: 'equipment.jpg'),
      // });
      // final response = await DioClient.instance.post('/api/upload', data: formData);
      // return response.data['url'];

      // Simulate a small delay for network upload simulation
      await Future.delayed(const Duration(milliseconds: 600));

      // Return a simulated cloud storage image URL
      return "https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&w=600&q=80";
    } catch (e) {
      throw Exception("Upload failed: $e");
    }
  }

  // ─────────────────────────────────────────────
  // Submit Flow
  // ─────────────────────────────────────────────
  Future<void> submitEquipment() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<EquipmentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isSaving = true);

    String uploadedImageUrl = '';
    if (_imageFile != null) {
      try {
        uploadedImageUrl = await _uploadImage(_imageFile!);
      } catch (e) {
        setState(() => _isSaving = false);
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
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
            content: Text("Equipment Listing Created!"),
            behavior: SnackBarBehavior.floating,
          ),
        );
        navigator.pop();
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
      appBar: AppBar(
        title: const Text("List Medical Equipment", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                            ),
                            child: _imageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: Image.file(
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 36,
                                    color: AppColors.primary,
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
                                padding: const EdgeInsets.all(4),
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
                  const SizedBox(height: 30),

                  // Equipment Name
                  buildTextField(
                    controller: _nameController,
                    label: "Equipment Name",
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
                        labelText: "Category",
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
                        setState(() {
                          selectedCategory = value!;
                        });
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
                    label: "Quantity",
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
                        labelText: "Condition",
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
                        setState(() {
                          selectedCondition = value!;
                        });
                      },
                    ),
                  ),

                  // Location
                  buildTextField(
                    controller: _locationController,
                    label: "Location",
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
                      onPressed: submitEquipment,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text(
                        "Submit Listing",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}