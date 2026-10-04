import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../models/rental_model.dart';
import '../../models/delivery_model.dart';
import '../../services/delivery_service.dart';

class AssignDeliveryPartnerScreen extends StatelessWidget {
  final RentalModel rental;

  const AssignDeliveryPartnerScreen({super.key, required this.rental});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Delivery Partner'),
        backgroundColor: context.surfaceBg,
        foregroundColor: context.textPrimaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'DELIVERY_PARTNER')
            // .where('isAvailable', isEqualTo: true) // Assuming you have this
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final partners = snapshot.data?.docs ?? [];
          if (partners.isEmpty) {
             return const Center(child: Text('No delivery partners available.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: partners.length,
            itemBuilder: (context, index) {
              final partner = partners[index].data() as Map<String, dynamic>;
              final partnerId = partners[index].id;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        child: Icon(Icons.person),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              partner['name'] ?? 'Unknown Partner',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const Text('Delivery Partner'),
                            Text('Vehicle: ${partner['vehicle'] ?? 'N/A'}', style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Row(
                              children: const [
                                Icon(Icons.circle, color: Colors.green, size: 12),
                                SizedBox(width: 4),
                                Text('Available', style: TextStyle(color: Colors.green)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () async {
                          // Create delivery doc
                          final deliveryId = FirebaseFirestore.instance.collection('deliveries').doc().id;
                          final type = (rental.status == RentalStatus.RETURN_REQUESTED || rental.status == RentalStatus.RETURN_ASSIGNED || rental.status == RentalStatus.RETURN_PICKUP) 
                               ? DeliveryType.RETURN_PICKUP 
                               : DeliveryType.DELIVERY;

                          final newDelivery = DeliveryModel(
                             id: deliveryId,
                             rentalId: rental.id,
                             deliveryPartnerId: partnerId,
                             ngoId: rental.ngoId,
                             type: type,
                             status: DeliveryStatus.ASSIGNED,
                             pickupAddress: 'NGO Address', // Need actual lookup in production
                             deliveryAddress: 'Recipient Address', // Need actual lookup in production
                             createdAt: DateTime.now().toIso8601String(),
                             updatedAt: DateTime.now().toIso8601String(),
                          );
                          
                          await DeliveryService().createRental(newDelivery);
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Partner Assigned successfully!')),
                            );
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Assign'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

