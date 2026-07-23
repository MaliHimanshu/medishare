import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import '../../providers/equipment_provider.dart';

// Models
import '../../models/equipment_model.dart';

// Shared Constants
import '../../core/constants/app_colors.dart';

class EditEquipmentScreen extends StatefulWidget {
  final EquipmentModel equipment;

  const EditEquipmentScreen({
    super.key,
    required this.equipment,
  });

  @override
  State<EditEquipmentScreen> createState() => _EditEquipmentScreenState();
}

class _EditEquipmentScreenState extends State<EditEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _manufacturerController;
  late TextEditingController _quantityController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;

  late String selectedCategory;
  late String selectedCondition;
  late String selectedStatus;

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

  final List<String> statuses = [
    "AVAILABLE",
    "REQUESTED",
    "DONATED",
    "UNAVAILABLE",
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.equipment.name);
    _manufacturerController = TextEditingController(text: widget.equipment.manufacturer);
    _quantityController = TextEditingController(text: widget.equipment.quantity.toString());
    _locationController = TextEditingController(text: widget.equipment.location);
    _descriptionController = TextEditingController(text: widget.equipment.description);
    
    // Fallbacks if current value doesn't match list items exactly
    selectedCategory = categories.contains(widget.equipment.category)
        ? widget.equipment.category
        : categories.first;

    final upperCond = widget.equipment.condition.toUpperCase();
    selectedCondition = conditions.contains(upperCond)
        ? upperCond
        : conditions.first;

    final upperStatus = widget.equipment.status.toUpperCase();
    selectedStatus = statuses.contains(upperStatus)
        ? upperStatus
        : statuses.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> submitEquipment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final success = await context.read<EquipmentProvider>().updateEquipment(
          widget.equipment.id,
          name: _nameController.text.trim(),
          category: selectedCategory,
          condition: selectedCondition,
          quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
          status: selectedStatus,
          manufacturer: _manufacturerController.text.trim(),
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
        );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Listing Updated Successfully!"),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        final err = context.read<EquipmentProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err.isNotEmpty ? err : "Failed to update listing."),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Edit Medical Equipment", style: TextStyle(fontWeight: FontWeight.bold)),
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
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_note_outlined,
                        size: 44,
                        color: AppColors.primary,
                      ),
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
                      decoration: InputDecoration(
                        labelText: "Category",
                        prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primary),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
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
                      decoration: InputDecoration(
                        labelText: "Condition",
                        prefixIcon: const Icon(Icons.health_and_safety_outlined, color: AppColors.primary),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
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

                  // Status Dropdown
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: InputDecoration(
                        labelText: "Availability Status",
                        prefixIcon: const Icon(Icons.info_outline, color: AppColors.primary),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                        ),
                      ),
                      items: statuses.map((stat) {
                        return DropdownMenuItem(
                          value: stat,
                          child: Text(stat),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value!;
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
                        "Save Updates",
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