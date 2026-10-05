import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../../core/constants/app_colors.dart';
import '../../models/delivery_model.dart';
import '../../services/delivery_service.dart';
import '../../services/rental_service.dart';
import '../../models/delivery_partner_model.dart';
import 'assign_delivery_partner_screen.dart';
import 'live_tracking_screen.dart';

class AdminDeliveryManagementScreen extends StatefulWidget {
  const AdminDeliveryManagementScreen({super.key});

  @override
  State<AdminDeliveryManagementScreen> createState() => _AdminDeliveryManagementScreenState();
}

class _AdminDeliveryManagementScreenState extends State<AdminDeliveryManagementScreen> {
  final DeliveryService _deliveryService = DeliveryService();
  String _searchQuery = '';
  String _selectedStatus = 'ALL';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Delivery Management'),
        backgroundColor: context.surfaceBg,
        foregroundColor: context.textPrimaryColor,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildDeliveryList()),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _printDiagnostics();
  }

  Future<void> _printDiagnostics() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('[DIAGNOSTICS] No Firebase Auth user found.');
        return;
      }
      debugPrint('[DIAGNOSTICS] Firebase Auth UID: ${user.uid}');
      debugPrint('[DIAGNOSTICS] Authenticated Email: ${user.email}');
      
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      debugPrint('[DIAGNOSTICS] Firestore users/${user.uid} exists: ${doc.exists}');
      if (doc.exists) {
        debugPrint('[DIAGNOSTICS] Firestore users/${user.uid}.role: ${doc.data()?['role']}');
      }

      // We can also print the PostgreSQL role from the provider if we pass context or just rely on what's in local storage
      final cachedUserStr = await const FlutterSecureStorage().read(key: 'medishare_user');
      if (cachedUserStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(cachedUserStr);
        debugPrint('[DIAGNOSTICS] PostgreSQL/cached role: ${userMap['role']}');
      }
    } catch (e) {
      debugPrint('[DIAGNOSTICS] Error reading diagnostics: $e');
    }
  }

  Widget _buildFilters() {
    return Container(
      color: context.surfaceBg,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search Delivery ID or Rental ID...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim().toLowerCase();
              });
            },
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'ALL',
                ...DeliveryStatus.values.map((e) => e.name)
              ].map((status) {
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status.replaceAll('_', ' ')),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        _selectedStatus = status;
                      });
                    },
                    selectedColor: AppColors.primary.withAlpha(50),
                    checkmarkColor: AppColors.primary,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryList() {
    return StreamBuilder<List<DeliveryModel>>(
      stream: _deliveryService.streamAllDeliveries(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var deliveries = snapshot.data ?? [];

        // Apply filters
        if (_selectedStatus != 'ALL') {
          deliveries = deliveries.where((d) => d.status.name == _selectedStatus).toList();
        }
        if (_searchQuery.isNotEmpty) {
          deliveries = deliveries.where((d) => 
            d.id.toLowerCase().contains(_searchQuery) ||
            d.rentalId.toLowerCase().contains(_searchQuery)
          ).toList();
        }

        if (deliveries.isEmpty) {
          return const Center(child: Text('No deliveries found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: deliveries.length,
          itemBuilder: (context, index) {
            final delivery = deliveries[index];
            return _buildDeliveryCard(delivery);
          },
        );
      },
    );
  }

  Widget _buildDeliveryCard(DeliveryModel delivery) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Delivery: ${delivery.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(delivery.status).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    delivery.status.name.replaceAll('_', ' '),
                    style: TextStyle(
                      color: _getStatusColor(delivery.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Rental ID: ${delivery.rentalId}', style: TextStyle(color: context.textSecondaryColor, fontSize: 13)),
            Text('Type: ${delivery.type.name}', style: TextStyle(color: context.textSecondaryColor, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.store, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(child: Text('Pickup: ${delivery.pickupAddress}', style: const TextStyle(fontSize: 13))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text('Destination: ${delivery.deliveryAddress}', style: const TextStyle(fontSize: 13))),
              ],
            ),
            const SizedBox(height: 8),
            Text('Created: ${delivery.createdAt}', style: TextStyle(color: context.textSecondaryColor, fontSize: 12)),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      // Need rental to assign
                      final rental = await RentalService().getRental(delivery.rentalId);
                      if (rental == null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rental details not found.')));
                        return;
                      }
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AssignDeliveryPartnerScreen(
                              rental: rental!,
                              existingDeliveryId: delivery.id,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Reassign Partner'),
                  ),
                ),
                if (delivery.status == DeliveryStatus.IN_TRANSIT || delivery.status == DeliveryStatus.PICKED_UP) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        // Navigate to LiveTrackingScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LiveTrackingScreen(
                              deliveryId: delivery.id,
                              partner: DeliveryPartnerModel(
                                id: delivery.deliveryPartnerId,
                                userId: delivery.deliveryPartnerId,
                                ngoId: delivery.ngoId,
                                fullName: 'Delivery Partner',
                                phone: '',
                                profilePhoto: '',
                                vehicleType: VehicleType.OTHER,
                                vehicleNumber: '',
                                isAvailable: false,
                                createdAt: '',
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.location_searching, size: 18),
                      label: const Text('Track'),
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.ASSIGNED:
        return Colors.orange;
      case DeliveryStatus.IN_TRANSIT:
      case DeliveryStatus.PICKED_UP:
      case DeliveryStatus.GOING_TO_PICKUP:
        return Colors.blue;
      case DeliveryStatus.DELIVERED:
      case DeliveryStatus.COMPLETED:
        return Colors.green;
      case DeliveryStatus.CANCELLED:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
