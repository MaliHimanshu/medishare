import 'package:flutter/material.dart';
import '../../models/equipment_model.dart';
import 'equipment_detail_screen.dart';

class EquipmentListScreen extends StatelessWidget {
  const EquipmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<EquipmentModel> equipmentList = [
      EquipmentModel(
        id: "1",
        name: "Wheelchair",
        category: "Mobility",
        description: "Comfortable manual wheelchair.",
        location: "Ahmedabad",
        quantity: 5,
        status: "Available",
        donor: "City Hospital",
        condition: "Excellent",
      ),
      EquipmentModel(
        id: "2",
        name: "Oxygen Cylinder",
        category: "Respiratory",
        description: "Portable oxygen cylinder.",
        location: "Surat",
        quantity: 8,
        status: "Available",
        donor: "Apollo Hospital",
        condition: "Good",
      ),
      EquipmentModel(
        id: "3",
        name: "Hospital Bed",
        category: "Furniture",
        description: "Adjustable hospital bed.",
        location: "Vadodara",
        quantity: 3,
        status: "Available",
        donor: "NGO Care",
        condition: "Excellent",
      ),
      EquipmentModel(
        id: "4",
        name: "Ventilator",
        category: "Critical Care",
        description: "ICU Ventilator.",
        location: "Rajkot",
        quantity: 2,
        status: "Available",
        donor: "Civil Hospital",
        condition: "New",
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Medical Equipment"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search Equipment",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: equipmentList.length,
              itemBuilder: (context, index) {
                final equipment = equipmentList[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),

                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.blue.shade100,
                      child: const Icon(
                        Icons.medical_services,
                        color: Colors.blue,
                      ),
                    ),

                    title: Text(
                      equipment.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 5),

                        Text(
                          equipment.location,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          "Quantity : ${equipment.quantity}",
                        ),

                        const SizedBox(height: 6),

                        Chip(
                          label: Text(equipment.status),
                          backgroundColor: Colors.green.shade100,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),

                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EquipmentDetailScreen(
                            equipment: equipment,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}