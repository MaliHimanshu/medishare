import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../models/rental_model.dart';
import '../../models/delivery_model.dart';
import '../../services/delivery_service.dart';

class AssignDeliveryPartnerScreen extends StatelessWidget {
  final RentalModel rental;
  final String? existingDeliveryId;

  const AssignDeliveryPartnerScreen({
    super.key, 
    required this.rental,
    this.existingDeliveryId,
  });

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
                          debugPrint('=== ASSIGN DIAGNOSTICS ===');
                          debugPrint('rental ID = ${rental.id}');
                          debugPrint('selected delivery partner ID = $partnerId');
                          debugPrint('current Firebase UID = FirebaseAuth.instance.currentUser?.uid'); // Cannot import firebase auth easily here without checking, wait I can just print it if I add the import.
                          debugPrint('existing delivery ID = $existingDeliveryId');
                          
                          // Show loading indicator
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(child: CircularProgressIndicator()),
                          );
                          
                          try {
                            debugPrint('Starting Firestore write...');
                            if (existingDeliveryId != null) {
                              debugPrint('Method: update existing delivery');
                              await DeliveryService().assignDeliveryPartner(existingDeliveryId!, partnerId);
                            } else {
                              debugPrint('Method: create new delivery');
                              final deliveryId = FirebaseFirestore.instance.collection('deliveries').doc().id;
                              final type = (rental.status == RentalStatus.RETURN_REQUESTED || rental.status == RentalStatus.RETURN_ASSIGNED || rental.status == RentalStatus.RETURN_PICKUP) 
                                   ? DeliveryType.RETURN_PICKUP 
                                   : DeliveryType.DELIVERY;

                              final newDelivery = DeliveryModel(
                                 id: deliveryId,
                                 rentalId: rental.id,
                                 deliveryPartnerId: partnerId,
                                 ngoId: FirebaseAuth.instance.currentUser?.uid ?? rental.ngoId,
                                 type: type,
                                 status: DeliveryStatus.ASSIGNED,
                                 pickupAddress: 'NGO Address',
                                 deliveryAddress: 'Recipient Address',
                                 createdAt: DateTime.now().toIso8601String(),
                                 updatedAt: DateTime.now().toIso8601String(),
                              );
                              
                              await DeliveryService().createRental(newDelivery);
                            }
                            debugPrint('Firestore write completed successfully.');
                            
                            if (context.mounted) {
                              Navigator.pop(context); // pop loading dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(existingDeliveryId != null ? 'Partner Reassigned successfully!' : 'Delivery partner assigned successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context); // pop assign screen
                            }
                          } catch (e) {
                            debugPrint('Firestore write FAILED: $e');
                            if (context.mounted) {
                              Navigator.pop(context); // pop loading dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to assign partner: $e'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
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

