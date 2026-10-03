import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

// Providers
import '../../providers/auth_provider.dart';
import '../../providers/tracking_provider.dart';

// Models
import '../../models/rental_model.dart';

// UI Helpers
import '../../core/constants/app_colors.dart';

class LiveTrackingScreen extends StatefulWidget {
  final RentalModel rental;

  const LiveTrackingScreen({super.key, required this.rental});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _mapController = MapController();
  bool _autoCenter = true;
  bool _showBaseLocation = true;
  bool _showTrail = true;
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    final trackingProv = context.read<TrackingProvider>();
    
    // Viewer mode: start polling Firestore for the latest delivery position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      trackingProv.startPolling(widget.rental.id);
    });
  }

  @override
  void dispose() {
    final trackingProv = context.read<TrackingProvider>();
    trackingProv.stopPolling();
    super.dispose();
  }

  void _centerMapOn(LatLng target) {
    _mapController.move(target, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final trackingProv = context.watch<TrackingProvider>();

    final currentUserId = authProv.user?.id;
    final isRenter = currentUserId == widget.rental.renterId;

    // Base equipment location
    final double baseLat = widget.rental.equipment?.latitude ?? 23.0225;
    final double baseLng = widget.rental.equipment?.longitude ?? 72.5714;
    final LatLng baseLocation = LatLng(baseLat, baseLng);

    // Live location
    LatLng? liveLocation;
    final latestPing = trackingProv.currentSession?.latestPing;
    if (latestPing != null) {
      liveLocation = LatLng(latestPing.latitude, latestPing.longitude);
    }

    // Auto-center logic
    if (_autoCenter && _isInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (liveLocation != null) {
          _centerMapOn(liveLocation);
          _isInit = false;
        } else {
          _centerMapOn(baseLocation);
          _isInit = false;
        }
      });
    } else if (_autoCenter && liveLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerMapOn(liveLocation!);
      });
    }

    // Build map markers
    final List<Marker> markers = [];

    // 1. Static Base Equipment location
    if (_showBaseLocation) {
      markers.add(
        Marker(
          point: baseLocation,
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Equipment Base Location: ${widget.rental.equipment?.name ?? "Base"}',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(color: Colors.teal.shade700, width: 2),
              ),
              child: Icon(
                Icons.home_work,
                color: Colors.teal.shade700,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }

    // 2. Live tracker location
    if (liveLocation != null) {
      markers.add(
        Marker(
          point: liveLocation,
          width: 60,
          height: 60,
          child: Column(
            children: [
              // Custom pulsing-style dot
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isRenter ? 'Partner' : 'Partner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Connect them with polyline history trail
    final List<LatLng> historyPoints = trackingProv.history
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Live Tracking'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: context.textPrimaryColor,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () {
              trackingProv.startPolling(widget.rental.id);
            },
            tooltip: 'Refresh Location',
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map Layer ──────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: liveLocation ?? baseLocation,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.medishare.app',
              ),
              if (_showTrail && historyPoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: historyPoints,
                      color: AppColors.primary.withValues(alpha: 0.7),
                      strokeWidth: 4.5,
                      borderColor: Colors.white,
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
          ),

          // ── Map Controls & Overlays ────────────────────────────
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                _buildMapActionButton(
                  icon: _autoCenter ? Icons.gps_fixed : Icons.gps_not_fixed,
                  tooltip: 'Auto-center on tracker',
                  color: _autoCenter ? AppColors.primary : context.cardBg,
                  iconColor: _autoCenter ? Colors.white : context.textPrimaryColor,
                  onPressed: () => setState(() => _autoCenter = !_autoCenter),
                ),
                const SizedBox(height: 10),
                _buildMapActionButton(
                  icon: _showBaseLocation
                      ? Icons.home_work
                      : Icons.home_work_outlined,
                  tooltip: 'Toggle Base Location Pin',
                  color: context.cardBg,
                  iconColor: _showBaseLocation
                      ? Colors.teal.shade700
                      : context.textSecondaryColor,
                  onPressed: () =>
                      setState(() => _showBaseLocation = !_showBaseLocation),
                ),
                const SizedBox(height: 10),
                _buildMapActionButton(
                  icon: _showTrail ? Icons.gesture : Icons.gesture_outlined,
                  tooltip: 'Toggle Trail History',
                  color: context.cardBg,
                  iconColor: _showTrail ? AppColors.primary : context.textSecondaryColor,
                  onPressed: () => setState(() => _showTrail = !_showTrail),
                ),
              ],
            ),
          ),

          // ── Error Message Overlay ──────────────────────────────
          if (trackingProv.errorMessage.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 80,
              child: Card(
                color: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          trackingProv.errorMessage,
                          style: TextStyle(color: Colors.red, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Bottom Panel Overlay (Premium Card) ────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(
              trackingProv,
              isRenter,
              liveLocation,
              baseLocation,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildBottomPanel(
    TrackingProvider trackingProv,
    bool isRenter,
    LatLng? liveLocation,
    LatLng baseLocation,
  ) {
    final latestPing = trackingProv.currentSession?.latestPing;
    final isSessionActive =
        trackingProv.currentSession?.isTrackingActive ?? false;

    // Calculate dynamic distance label if both coordinates are present
    String distanceStr = "Awaiting live GPS...";
    if (liveLocation != null) {
      final double distance = Geolocator.distanceBetween(
        baseLocation.latitude,
        baseLocation.longitude,
        liveLocation.latitude,
        liveLocation.longitude,
      );
      if (distance < 1000) {
        distanceStr = "${distance.toStringAsFixed(0)} meters from base";
      } else {
        distanceStr = "${(distance / 1000).toStringAsFixed(1)} km from base";
      }
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      color: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.rental.equipment?.name ?? 'Live Tracking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        distanceStr,
                        style: TextStyle(
                          fontSize: 13,
                          color: liveLocation != null
                              ? AppColors.primary
                              : context.textSecondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isSessionActive
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSessionActive
                          ? Colors.green.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSessionActive ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isSessionActive ? 'ONLINE' : 'OFFLINE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSessionActive
                              ? Colors.green.shade800
                              : context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Removed Renter location sharing toggle as Delivery Partner shares location.
            // Viewer metadata metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricCell(
                  icon: Icons.speed,
                  title: 'Speed',
                  value: latestPing?.speed != null && latestPing!.speed! > 0
                      ? '${(latestPing.speed! * 3.6).toStringAsFixed(1)} km/h'
                      : '--',
                ),
                _buildMetricCell(
                  icon: Icons.radar,
                  title: 'Accuracy',
                  value: latestPing?.accuracy != null && latestPing!.accuracy! > 0
                      ? '${latestPing.accuracy!.toStringAsFixed(0)} m'
                      : '--',
                ),
                _buildMetricCell(
                  icon: Icons.timer_outlined,
                  title: 'Updated',
                  value: latestPing != null
                      ? _formatRecordedTime(latestPing.recordedAt)
                      : '--',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCell({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary.withValues(alpha: 0.8)),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRecordedTime(DateTime recordedAt) {
    final diff = DateTime.now().difference(recordedAt);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }
}
