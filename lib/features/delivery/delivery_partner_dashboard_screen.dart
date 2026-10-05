import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_endpoints.dart';
import '../../services/location_service.dart';
import '../../services/delivery_service.dart';
import '../../services/rental_service.dart';
import '../../models/delivery_model.dart';
import '../../models/rental_model.dart';
import '../../providers/auth_provider.dart';
import 'pickup_confirmation_screen.dart';
import 'otp_verification_screen.dart';

class DeliveryPartnerDashboardScreen extends StatelessWidget {
  const DeliveryPartnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final partnerId = Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';
    final deliveryService = DeliveryService();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Partner Dashboard'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Today's Tasks"),
              Tab(text: 'Active Delivery'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: StreamBuilder<List<DeliveryModel>>(
          stream: deliveryService.streamDeliveriesByPartner(partnerId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final deliveries = snapshot.data ?? [];
            final assigned = deliveries.where((d) => d.status == DeliveryStatus.ASSIGNED).toList();
            final active = deliveries.where((d) => d.status == DeliveryStatus.GOING_TO_PICKUP || d.status == DeliveryStatus.IN_TRANSIT || d.status == DeliveryStatus.PICKED_UP).toList();
            final completed = deliveries.where((d) => d.status == DeliveryStatus.DELIVERED || d.status == DeliveryStatus.CANCELLED).toList();

            return TabBarView(
              children: [
                _buildTaskList(context, assigned, 'ASSIGNED'),
                _buildTaskList(context, active, 'ACTIVE'),
                const Center(child: Text('No upcoming tasks')),
                _buildTaskList(context, completed, 'COMPLETED'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, List<DeliveryModel> list, String tabType) {
    if (list.isEmpty) {
      return Center(
        child: Text('No $tabType tasks', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final delivery = list[index];
        final status = delivery.status.name.toUpperCase();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivery: ${delivery.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Type: ${delivery.type.name}'),
                Text('Pickup: ${delivery.pickupAddress}'),
                Text('Destination: ${delivery.deliveryAddress}'),
                const SizedBox(height: 8),
                Text('Status: $status', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                if (status == 'ASSIGNED')
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        debugPrint('=== [START PICKUP] DIAGNOSTICS ===');
                        debugPrint('deliveryId = ${delivery.id}');
                        debugPrint('firebaseUid = ${Provider.of<AuthProvider>(context, listen: false).user?.id}');
                        debugPrint('deliveryPartnerId = ${delivery.deliveryPartnerId}');
                        debugPrint('currentStatus = $status');
                        debugPrint('requestedStatus = GOING_TO_PICKUP');
                        
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(child: CircularProgressIndicator()),
                        );
                        
                        try {
                          debugPrint('update started');
                          await DeliveryService().updateDeliveryStatus(delivery.id, DeliveryStatus.GOING_TO_PICKUP);
                          debugPrint('update completed');
                          
                          if (context.mounted) {
                            Navigator.pop(context); // close dialog
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated to GOING TO PICKUP'), backgroundColor: Colors.green));
                          }
                        } catch (e) {
                          debugPrint('FirebaseException code/message: $e');
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red));
                          }
                        }
                      },
                      child: const Text('Start Pickup'),
                    ),
                  ),

                if (status == 'GOING_TO_PICKUP')
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        debugPrint('=== [ARRIVED PICKUP DEBUG] ===');
                        debugPrint('deliveryId = ${delivery.id}');
                        debugPrint('delivery.rentalId = ${delivery.rentalId}');
                        debugPrint('firebaseUserId = ${Provider.of<AuthProvider>(context, listen: false).user?.id}');
                        debugPrint('userRole = ${Provider.of<AuthProvider>(context, listen: false).user?.role}');
                        debugPrint('API base URL = ${ApiEndpoints.baseUrl}');
                        debugPrint('GET rental URL = ${ApiEndpoints.rental}/${delivery.rentalId}');

                        RentalModel? rental;
                        try {
                          rental = await RentalService().getRental(delivery.rentalId);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('API Error: $e'), duration: const Duration(seconds: 5)));
                          }
                          return;
                        }

                        debugPrint('rental found = ${rental != null}');
                        
                        if (rental == null && context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rental details not found.')));
                           return;
                        }
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PickupConfirmationScreen(
                                deliveryId: delivery.id,
                                rentalId: delivery.rentalId,
                                equipmentId: rental!.equipmentId,
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Arrived at Pickup (Take Photo)'),
                    ),
                  ),
                  
                if (status == 'IN_TRANSIT' || status == 'PICKED_UP' || status == 'RETURN_PICKED_UP')
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        print('[START DELIVERY] Button tapped');
                        print('[START DELIVERY] Delivery ID: ${delivery.id}');
                        print('[START DELIVERY] Current status: $status');
                        
                        try {
                          final locationService = LocationService();
                          await locationService.startTracking(delivery.id);
                          
                          if (status == 'PICKED_UP') {
                            print('[START DELIVERY] Updating status to IN_TRANSIT');
                            await DeliveryService().updateDeliveryStatus(delivery.id, DeliveryStatus.IN_TRANSIT);
                            print('[START DELIVERY] Update completed');
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Delivery started. Live tracking active.')),
                            );
                          }
                        } catch (e) {
                          print('[START DELIVERY] Failed: $e');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to start delivery: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      child: Text(
                        status == 'RETURN_PICKED_UP' ? 'Start Return Delivery' : 'Start Delivery'
                      ),
                    ),
                  ),
                  
                if (status == 'IN_TRANSIT')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        print('[DELIVERY OTP] Button tapped');
                        print('[DELIVERY OTP] Delivery ID: ${delivery.id}');
                        print('[DELIVERY OTP] Current status: $status');
                        print('[DELIVERY OTP] Request started');
                        
                        try {
                          final rental = await RentalService().getRental(delivery.rentalId);
                          print('[DELIVERY OTP] Request completed');
                          
                          if (rental == null && context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rental details not found.')));
                             return;
                          }
                          if (context.mounted) {
                            print('[DELIVERY OTP] Opening OTP screen');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OtpVerificationScreen(
                                  deliveryId: delivery.id,
                                  rental: rental!,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          print('[DELIVERY OTP] Error: $e');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to load rental details: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      child: const Text('Enter Delivery OTP'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
