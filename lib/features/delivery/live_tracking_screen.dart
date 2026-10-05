import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/delivery_partner_model.dart';
import '../../models/delivery_model.dart';
import '../../services/delivery_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String deliveryId;
  final DeliveryPartnerModel partner;
  
  const LiveTrackingScreen({
    super.key, 
    required this.deliveryId,
    required this.partner,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _mapController = MapController();
  final DeliveryService _deliveryService = DeliveryService();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  bool _isValidCoordinate(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;
    if (lat == 0 && lng == 0) return false;
    return true;
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null || isoTime.isEmpty) return 'Location update unavailable';
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      return 'Last updated: ${DateFormat.jm().format(dt)}';
    } catch (_) {
      return 'Location update unavailable';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Delivery'),
        backgroundColor: context.surfaceBg,
        foregroundColor: context.textPrimaryColor,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.circle, color: Colors.green, size: 10),
                SizedBox(width: 4),
                Text('LIVE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
      body: StreamBuilder<DeliveryModel?>(
        stream: _deliveryService.streamDelivery(widget.deliveryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final delivery = snapshot.data;
          if (delivery == null) {
            return const Center(child: Text('Delivery not found'));
          }

          final hasLocation = _isValidCoordinate(delivery.currentLatitude, delivery.currentLongitude);
          
          LatLng? partnerLocation;
          if (hasLocation) {
            partnerLocation = LatLng(delivery.currentLatitude!, delivery.currentLongitude!);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                // Move map to new location
                _mapController.move(partnerLocation!, _mapController.camera.zoom);
              }
            });
          }

          return Stack(
            children: [
              if (hasLocation) 
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: partnerLocation!,
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.medishare',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: partnerLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.delivery_dining, color: Colors.blue, size: 40),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Container(
                  color: context.scaffoldBg,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_searching, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Waiting for delivery partner location...', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ETA', style: TextStyle(color: context.textSecondaryColor, fontSize: 12)),
                            const Text('15 Mins', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status', style: TextStyle(color: context.textSecondaryColor, fontSize: 12)),
                            Text(delivery.status.name.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Last updated', style: TextStyle(color: context.textSecondaryColor, fontSize: 12)),
                            Text(_formatTime(delivery.lastLocationUpdate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, -5))
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: widget.partner.profilePhoto.isNotEmpty
                                ? NetworkImage(widget.partner.profilePhoto)
                                : null,
                            child: widget.partner.profilePhoto.isEmpty ? const Icon(Icons.person) : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.partner.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Delivery Partner - NGO', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                Text('${widget.partner.vehicleType.name} • ${widget.partner.vehicleNumber}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.call),
                              label: const Text('Call'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.chat),
                              label: const Text('Contact'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}
