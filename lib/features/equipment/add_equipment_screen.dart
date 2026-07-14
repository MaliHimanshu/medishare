import 'package:flutter/material.dart';

class AddEquipmentScreen extends StatefulWidget {
  const AddEquipmentScreen({super.key});

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _donorController = TextEditingController();
  final _phoneController = TextEditingController();

  String selectedCategory = "Mobility";

  final List<String> categories = [
    "Mobility",
    "Respiratory",
    "Critical Care",
    "Furniture",
    "Diagnostic",
    "Surgical",
    "Other",
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _donorController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void submitEquipment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Equipment Added Successfully"),
      ),
    );
  }

  Widget buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Equipment"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            CircleAvatar(
              radius: 55,
              backgroundColor: Colors.blue.shade100,
              child: IconButton(
                icon: const Icon(
                  Icons.camera_alt,
                  size: 35,
                  color: Colors.blue,
                ),
                onPressed: () {},
              ),
            ),

            const SizedBox(height: 30),

            buildField(
              controller: _nameController,
              label: "Equipment Name",
              icon: Icons.medical_services,
            ),

            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
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

            const SizedBox(height: 18),

            buildField(
              controller: _descriptionController,
              label: "Description",
              icon: Icons.description,
              maxLines: 4,
            ),

            buildField(
              controller: _quantityController,
              label: "Quantity",
              icon: Icons.inventory,
              keyboard: TextInputType.number,
            ),

            buildField(
              controller: _locationController,
              label: "Location",
              icon: Icons.location_on,
            ),

            buildField(
              controller: _donorController,
              label: "Hospital / NGO Name",
              icon: Icons.local_hospital,
            ),

            buildField(
              controller: _phoneController,
              label: "Contact Number",
              icon: Icons.phone,
              keyboard: TextInputType.phone,
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: submitEquipment,
                icon: const Icon(Icons.save),
                label: const Text(
                  "Submit Equipment",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}