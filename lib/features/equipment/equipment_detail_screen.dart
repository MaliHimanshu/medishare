import 'package:flutter/material.dart';
import '../../models/equipment_model.dart';

class EquipmentDetailScreen extends StatelessWidget {
  final EquipmentModel equipment;

  const EquipmentDetailScreen({
    super.key,
    required this.equipment,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(equipment.name),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Center(
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.blue.shade100,
                child: const Icon(
                  Icons.medical_services,
                  color: Colors.blue,
                  size: 70,
                ),
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: Text(
                equipment.name,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Center(
              child: Chip(
                label: Text(equipment.status),
                backgroundColor: Colors.green.shade100,
              ),
            ),

            const SizedBox(height: 30),

            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(15),

                child: Column(
                  children: [

                    ListTile(
                      leading: const Icon(Icons.category),
                      title: const Text("Category"),
                      subtitle: Text(equipment.category),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text("Location"),
                      subtitle: Text(equipment.location),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(Icons.inventory),
                      title: const Text("Quantity"),
                      subtitle: Text(
                        equipment.quantity.toString(),
                      ),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(Icons.health_and_safety),
                      title: const Text("Condition"),
                      subtitle: Text(equipment.condition),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text("Donor"),
                      subtitle: Text(equipment.donor),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Description",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              equipment.description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "${equipment.name} requested successfully!",
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text(
                  "Request Equipment",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}