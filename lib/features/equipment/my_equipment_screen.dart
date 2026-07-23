import 'package:flutter/material.dart';
import 'edit_equipment_screen.dart';
import '../../models/equipment_model.dart';

class MyEquipmentScreen extends StatelessWidget {
  const MyEquipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    //========================
    // DUMMY EQUIPMENT DATA
    //========================

    final List<Map<String, dynamic>> equipmentList = [

      {
        "name": "Wheelchair",
        "category": "Mobility",
        "quantity": 5,
        "condition": "Excellent",
        "location": "Ahmedabad",
        "status": "Available",
      },

      {
        "name": "Hospital Bed",
        "category": "Furniture",
        "quantity": 2,
        "condition": "Good",
        "location": "Surat",
        "status": "Available",
      },

      {
        "name": "Oxygen Cylinder",
        "category": "Respiratory",
        "quantity": 6,
        "condition": "New",
        "location": "Vadodara",
        "status": "Donated",
      },

      {
        "name": "Walker",
        "category": "Mobility",
        "quantity": 3,
        "condition": "Good",
        "location": "Rajkot",
        "status": "Available",
      },
    ];
        return Scaffold(

      //==================================================
      // APP BAR
      //==================================================

      appBar: AppBar(
        title: const Text("My Equipment"),
        centerTitle: true,
      ),

      //==================================================
      // BODY
      //==================================================

      body: ListView.builder(

        padding: const EdgeInsets.all(15),

        itemCount: equipmentList.length,

        itemBuilder: (context, index) {

          final equipment = equipmentList[index];

          return Card(

            elevation: 5,

            margin: const EdgeInsets.only(bottom: 15),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),

            child: Padding(

              padding: const EdgeInsets.all(15),

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  //====================================
                  // HEADER
                  //====================================

                  Row(

                    children: [

                      CircleAvatar(

                        radius: 28,

                        backgroundColor:
                            Colors.blue.shade100,

                        child: const Icon(
                          Icons.medical_services,
                          color: Colors.blue,
                        ),
                      ),

                      const SizedBox(width: 15),

                      Expanded(

                        child: Column(

                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            Text(
                              equipment["name"],

                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            Text(
                              equipment["category"],
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Quantity : ${equipment["quantity"]}",
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Condition : ${equipment["condition"]}",
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Location : ${equipment["location"]}",
                  ),

                  const SizedBox(height: 12),

                  Chip(
                    label: Text(
                      equipment["status"],
                    ),
                  ),

                  const SizedBox(height: 20),
                                    //====================================
                  // ACTION BUTTONS
                  //====================================

                  Row(
                    children: [

                      //====================================
                      // EDIT BUTTON
                      //====================================

                      Expanded(
                        child: ElevatedButton.icon(

                          icon: const Icon(Icons.edit),

                          label: const Text("Edit"),

                          onPressed: () {
                            final model = EquipmentModel(
                              id: equipment['id']?.toString() ?? '',
                              name: equipment['name']?.toString() ?? '',
                              category: equipment['category']?.toString() ?? '',
                              description: equipment['description']?.toString() ?? '',
                              location: equipment['location']?.toString() ?? '',
                              quantity: equipment['quantity'] is int ? equipment['quantity'] : int.tryParse(equipment['quantity']?.toString() ?? '') ?? 1,
                              status: equipment['status']?.toString() ?? 'AVAILABLE',
                              donor: 'Donor',
                              condition: equipment['condition']?.toString() ?? 'GOOD',
                              manufacturer: 'Standard',
                              image: '',
                              ownerId: '',
                              createdAt: '',
                              updatedAt: '',
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditEquipmentScreen(equipment: model),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      //====================================
                      // DELETE BUTTON
                      //====================================

                      Expanded(
                        child: ElevatedButton.icon(

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),

                          icon: const Icon(Icons.delete),

                          label: const Text("Delete"),

                          onPressed: () {

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  "${equipment["name"]} deleted successfully",
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
            //==================================================
      // FLOATING ACTION BUTTON
      //==================================================

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text("Add Equipment"),

        onPressed: () {

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Navigate to Add Equipment Screen",
              ),
            ),
          );

          // Uncomment after integration
          /*
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEquipmentScreen(),
            ),
          );
          */
        },
      ),
    );
  }
}