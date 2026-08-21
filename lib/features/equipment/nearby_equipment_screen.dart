import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

// Providers
import '../../providers/equipment_provider.dart';

// Models
import '../../models/equipment_model.dart';

// Screens
import 'equipment_detail_screen.dart';

// Shared
import '../../shared/widgets/ms_skeleton.dart';
import '../../shared/widgets/ms_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_page_transitions.dart';

// ── Location State ────────────────────────────────────────────────────────────

enum _LocationState {
  idle,
  loading,
  granted,         // Fresh GPS fix acquired
  lastKnown,       // Using cached position (GPS timed out or service issue)
  serviceDisabled, // Location services (GPS toggle) is OFF
  permissionDenied,        // User denied once
  permissionDeniedForever, // User denied permanently
  timeout,         // getCurrentPosition() timed out, no last-known available
  unavailable,     // No position at all (no fix, no cache)
}

// ── Screen ────────────────────────────────────────────────────────────────────

class NearbyEquipmentScreen extends StatefulWidget {
  const NearbyEquipmentScreen({super.key});

  @override
  State<NearbyEquipmentScreen> createState() => _NearbyEquipmentScreenState();
}

class _NearbyEquipmentScreenState extends State<NearbyEquipmentScreen> {
  double _radius = 20;

  double? _latitude;
  double? _longitude;

  _LocationState _locationState = _LocationState.idle;

  /// True when the displayed coordinates come from getLastKnownPosition()
  /// rather than a fresh getCurrentPosition() fix.
  bool _isLastKnown = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // ── GPS Logic ──────────────────────────────────────────────────────────────

  /// Main location acquisition flow.
  /// 1. Service enabled?
  /// 2. Permission granted?
  /// 3. getCurrentPosition (30-second timeout)
  /// 4. On timeout/error → try getLastKnownPosition()
  /// 5. If nothing available → show unavailable error, do NOT call API
  Future<void> _determinePosition() async {
    if (!mounted) return;
    setState(() {
      _locationState = _LocationState.loading;
      _isLastKnown = false;
    });

    // ── Step 1: Location Service Check ────────────────────────────────────
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() => _locationState = _LocationState.serviceDisabled);
      // Still try last-known cache — Android sometimes has a stale fix
      // even when the location toggle is off (set before it was disabled).
      await _tryLastKnownOrStop(fallbackState: _LocationState.serviceDisabled);
      return;
    }

    // ── Step 2: Permission Check ──────────────────────────────────────────
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        setState(() => _locationState = _LocationState.permissionDenied);
        await _tryLastKnownOrStop(fallbackState: _LocationState.permissionDenied);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() => _locationState = _LocationState.permissionDeniedForever);
      await _tryLastKnownOrStop(fallbackState: _LocationState.permissionDeniedForever);
      return;
    }

    // ── Step 3: Fresh GPS Fix (30-second timeout) ─────────────────────────
    // ROOT CAUSE FIX: The base LocationSettings class does NOT support
    // timeLimit in geolocator 13.x. Only AndroidSettings/AppleSettings do.
    // Without platform-specific settings, getCurrentPosition hangs forever.
    try {
      LocationSettings locationSettings;
      if (Platform.isAndroid) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 30),
          forceLocationManager: false,
        );
      } else if (Platform.isIOS || Platform.isMacOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 30),
          pauseLocationUpdatesAutomatically: false,
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
        );
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(
        const Duration(seconds: 35),
        onTimeout: () => throw TimeoutException('GPS timed out after 35s'),
      );

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationState = _LocationState.granted;
        _isLastKnown = false;
      });

      _fetchNearby();
    } on TimeoutException {
      // ── Step 4: Timeout -> try last-known cache ───────────────────
      if (!mounted) return;
      setState(() => _locationState = _LocationState.timeout);
      await _tryLastKnownOrStop(fallbackState: _LocationState.timeout);
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationState = _LocationState.timeout);
      await _tryLastKnownOrStop(fallbackState: _LocationState.timeout);
    }
  }

  /// Tries getLastKnownPosition(). If a cached fix exists, uses it and
  /// fetches nearby equipment (with a clear "last known" label in the UI).
  /// If nothing is available, sets state to fallbackState and does NOT call API.
  Future<void> _tryLastKnownOrStop({required _LocationState fallbackState}) async {
    try {
      final Position? last = await Geolocator.getLastKnownPosition();
      if (!mounted) return;

      if (last != null) {
        setState(() {
          _latitude = last.latitude;
          _longitude = last.longitude;
          _isLastKnown = true;
          // Keep the original error state (serviceDisabled / timeout / etc.)
          // so the correct banner still renders, but results also show.
        });
        _fetchNearby();
      } else {
        // Nothing to offer — show correct error page
        setState(() => _locationState = fallbackState);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _locationState = fallbackState);
    }
  }

  // ── Equipment API ──────────────────────────────────────────────────────────

  void _fetchNearby() {
    if (_latitude == null || _longitude == null) return;
    context.read<EquipmentProvider>().fetchNearbyEquipment(
          latitude: _latitude!,
          longitude: _longitude!,
          radius: _radius,
        );
  }

  void _changeRadius(double newRadius) {
    setState(() => _radius = newRadius);
    _fetchNearby();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final equipProv = context.watch<EquipmentProvider>();
    final nearbyList = equipProv.nearbyEquipment;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Nearby Equipment'),
        centerTitle: true,
        backgroundColor: context.surfaceBg,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: AppColors.primary),
            onPressed: _determinePosition,
            tooltip: 'Retry Location',
          ),
        ],
      ),
      body: Column(
        children: [
          // Location & Radius Header
          _buildHeader(equipProv),

          // Results
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _fetchNearby(),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildBody(equipProv, nearbyList),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(EquipmentProvider equipProv) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.surfaceBg,
        border: Border(
          bottom: BorderSide(color: context.borderColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Location Info Row ──────────────────────────────────────────
          Row(
            children: [
              _buildLocationIcon(),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _locationLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (equipProv.nearbyMeta != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${equipProv.nearbyMeta!['count']} found",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),

          // ── Status Banner (non-fatal errors) ──────────────────────────
          if (_showInlineBanner()) ...[
            const SizedBox(height: 6),
            _buildInlineBanner(),
          ],

          const SizedBox(height: 10),

          // ── Radius Selector ────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Search Radius:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                _buildRadiusChip(5),
                const SizedBox(width: 6),
                _buildRadiusChip(10),
                const SizedBox(width: 6),
                _buildRadiusChip(20),
                const SizedBox(width: 6),
                _buildRadiusChip(50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationIcon() {
    switch (_locationState) {
      case _LocationState.granted:
        return const Icon(Icons.gps_fixed, size: 16, color: AppColors.success);
      case _LocationState.lastKnown:
      case _LocationState.timeout:
        return Icon(Icons.gps_not_fixed, size: 16, color: Colors.orange.shade600);
      case _LocationState.loading:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        );
      case _LocationState.serviceDisabled:
        return Icon(Icons.location_disabled, size: 16, color: Colors.red.shade400);
      case _LocationState.permissionDenied:
      case _LocationState.permissionDeniedForever:
        return Icon(Icons.lock_outline, size: 16, color: Colors.red.shade400);
      case _LocationState.unavailable:
        return Icon(Icons.gps_off, size: 16, color: Colors.red.shade400);
      case _LocationState.idle:
        return Icon(Icons.gps_not_fixed, size: 16, color: context.textSecondaryColor);
    }
  }

  String _locationLabel() {
    if (_locationState == _LocationState.loading) {
      return 'Getting your location…';
    }
    if (_latitude != null && _longitude != null) {
      final coords =
          '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}';
      return _isLastKnown ? 'Last known: $coords' : 'Location: $coords';
    }
    switch (_locationState) {
      case _LocationState.serviceDisabled:
        return 'Location services are disabled';
      case _LocationState.permissionDenied:
        return 'Location permission denied';
      case _LocationState.permissionDeniedForever:
        return 'Location permission permanently denied';
      case _LocationState.timeout:
      case _LocationState.unavailable:
        return 'Location unavailable';
      default:
        return 'Location unavailable';
    }
  }

  // ── Inline Banner (shown when we have a partial result + error) ────────────

  bool _showInlineBanner() {
    // Show a soft warning banner when results are present but location is
    // not fully reliable — e.g. last-known or timed-out.
    if (_latitude == null) return false;
    return _isLastKnown ||
        _locationState == _LocationState.timeout ||
        _locationState == _LocationState.serviceDisabled ||
        _locationState == _LocationState.permissionDenied ||
        _locationState == _LocationState.permissionDeniedForever;
  }

  Widget _buildInlineBanner() {
    String message;
    switch (_locationState) {
      case _LocationState.timeout:
        message =
            '⚠ GPS timed out — showing results for last known location. Tap ⊕ to retry.';
        break;
      case _LocationState.serviceDisabled:
        message =
            '⚠ Location services are OFF — showing last known location results.';
        break;
      case _LocationState.permissionDenied:
        message =
            '⚠ Permission denied — showing last known location results.';
        break;
      case _LocationState.permissionDeniedForever:
        message =
            '⚠ Permission permanently denied — showing last known location results.';
        break;
      default:
        message = '⚠ Using last known location. Tap ⊕ to refresh.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 11,
          color: Colors.orange.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── Radius Chips ───────────────────────────────────────────────────────────

  Widget _buildRadiusChip(double km) {
    final isSelected = _radius == km;
    return GestureDetector(
      onTap: () => _changeRadius(km),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : context.inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.borderColor,
            width: 1.5,
          ),
        ),
        child: Text(
          '${km.toInt()} km',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : context.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody(EquipmentProvider equipProv, List<EquipmentModel> list) {
    // 1. Acquiring location (no coords yet)
    if (_locationState == _LocationState.loading && _latitude == null) {
      return _buildFullScreenMessage(
        key: const ValueKey('location-loading'),
        icon: const CircularProgressIndicator(color: AppColors.primary),
        title: 'Getting your location…',
        subtitle: 'This may take up to 30 seconds for a cold GPS fix.',
      );
    }

    // 2. Full-screen blocking error states (no coords available at all)
    if (_latitude == null) {
      return _buildLocationErrorBody();
    }

    // 3. Loading nearby equipment (we have coords, waiting for API)
    if (equipProv.isLoadingNearby) {
      return ListView.builder(
        key: const ValueKey('loading'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: 4,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MsSkeleton(height: 120),
        ),
      );
    }

    // 4. API error
    if (equipProv.nearbyError.isNotEmpty) {
      return _buildFullScreenMessage(
        key: const ValueKey('api-error'),
        icon: const Icon(Icons.error_outline, size: 64, color: AppColors.error),
        title: 'Error Loading Nearby Equipment',
        subtitle: equipProv.nearbyError,
        actions: [
          ElevatedButton(
            onPressed: _fetchNearby,
            child: const Text('Try Again'),
          ),
        ],
      );
    }

    // 5. Empty results
    if (list.isEmpty) {
      return _buildFullScreenMessage(
        key: const ValueKey('empty'),
        icon: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.location_off_outlined,
              size: 54, color: AppColors.primary),
        ),
        title: 'No Equipment Nearby',
        subtitle:
            'No available equipment found within ${_radius.toInt()} km of your location. Try increasing the search radius.',
        actions: [
          OutlinedButton(
            onPressed: () => _changeRadius(50),
            child: const Text('Try 50 km Radius'),
          ),
        ],
      );
    }

    // 6. Success — list of nearby equipment
    return ListView.builder(
      key: const ValueKey('loaded'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final equipment = list[index];
        return AnimatedListItem(
          index: index,
          child: _buildNearbyCard(equipment),
        );
      },
    );
  }

  // ── Full-Screen Location Error States ──────────────────────────────────────

  Widget _buildLocationErrorBody() {
    switch (_locationState) {
      case _LocationState.serviceDisabled:
        return _buildFullScreenMessage(
          key: const ValueKey('service-disabled'),
          icon: Icon(Icons.location_disabled,
              size: 64, color: Colors.red.shade400),
          title: 'Location Services Disabled',
          subtitle:
              'GPS is turned off on your device. Please enable Location in your device settings and try again.',
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('Open Location Settings'),
              onPressed: () async {
                await Geolocator.openLocationSettings();
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              onPressed: _determinePosition,
            ),
          ],
        );

      case _LocationState.permissionDenied:
        return _buildFullScreenMessage(
          key: const ValueKey('permission-denied'),
          icon: Icon(Icons.lock_outline, size: 64, color: Colors.orange.shade600),
          title: 'Location Permission Denied',
          subtitle:
              'MediShare needs your location to find equipment nearby. Please grant permission.',
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.location_on, size: 18),
              label: const Text('Grant Permission'),
              onPressed: _determinePosition,
            ),
          ],
        );

      case _LocationState.permissionDeniedForever:
        return _buildFullScreenMessage(
          key: const ValueKey('permission-forever'),
          icon:
              Icon(Icons.lock, size: 64, color: Colors.red.shade400),
          title: 'Permission Permanently Denied',
          subtitle:
              'Location access was permanently denied. Open App Settings and enable Location permission for MediShare.',
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('Open App Settings'),
              onPressed: () async {
                await Geolocator.openAppSettings();
              },
            ),
          ],
        );

      case _LocationState.timeout:
        return _buildFullScreenMessage(
          key: const ValueKey('timeout'),
          icon:
              Icon(Icons.gps_off, size: 64, color: Colors.orange.shade600),
          title: 'GPS Timed Out',
          subtitle:
              'Could not get a GPS fix within 30 seconds and no cached location was found. Make sure you are outdoors or near a window, then retry.',
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('Retry Location'),
              onPressed: _determinePosition,
            ),
          ],
        );

      case _LocationState.unavailable:
        return _buildFullScreenMessage(
          key: const ValueKey('unavailable'),
          icon: Icon(Icons.gps_off, size: 64, color: Colors.red.shade400),
          title: 'Location Unavailable',
          subtitle:
              'No GPS fix or cached location is available. Ensure Location Services are ON and permission is granted, then retry.',
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('Retry Location'),
              onPressed: _determinePosition,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('Open Location Settings'),
              onPressed: () async {
                await Geolocator.openLocationSettings();
              },
            ),
          ],
        );

      default:
        return _buildFullScreenMessage(
          key: const ValueKey('unknown-error'),
          icon: Icon(Icons.gps_off, size: 64, color: Colors.red.shade400),
          title: 'Location Unavailable',
          subtitle: 'Could not determine your location.',
          actions: [
            ElevatedButton(
              onPressed: _determinePosition,
              child: const Text('Retry'),
            ),
          ],
        );
    }
  }

  // ── Generic Full-Screen Message Helper ─────────────────────────────────────

  Widget _buildFullScreenMessage({
    required Key key,
    required Widget icon,
    required String title,
    required String subtitle,
    List<Widget>? actions,
  }) {
    return ListView(
      key: key,
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        Center(
          child: Column(
            children: [
              icon,
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(color: context.textSecondaryColor),
                textAlign: TextAlign.center,
              ),
              if (actions != null) ...[
                const SizedBox(height: 24),
                ...actions,
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Nearby Equipment Card ──────────────────────────────────────────────────

  Widget _buildNearbyCard(EquipmentModel equipment) {
    Color statusColor = Colors.teal;
    if (equipment.status == 'REQUESTED') {
      statusColor = Colors.orange;
    } else if (equipment.status == 'DONATED') {
      statusColor = Colors.pink;
    } else if (equipment.status == 'UNAVAILABLE') {
      statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: context.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: context.borderColor, width: 1.5),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            AppPageTransitions.slideUp(
              EquipmentDetailScreen(equipment: equipment),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Equipment Image
              Container(
                width: 90,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: equipment.image.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          equipment.image,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.medical_services_outlined,
                            color: AppColors.primary,
                            size: 30,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.medical_services,
                        color: AppColors.primary,
                        size: 32,
                      ),
              ),
              const SizedBox(width: 14),

              // Equipment Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category + Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          equipment.category,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: context.textSecondaryColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            equipment.status,
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 8,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Name
                    Text(
                      equipment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11, color: Colors.grey),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            equipment.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11,
                                color: context.textSecondaryColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Condition + Mode chip + Distance
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Qty: ${equipment.quantity} · ${equipment.condition}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: context.textSecondaryColor),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Row(
                          children: [
                            if (equipment.distance != null)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${equipment.distance!.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            _buildModeChip(equipment.mode),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mode Chip ──────────────────────────────────────────────────────────────

  Widget _buildModeChip(String mode) {
    Color bg;
    Color fg;
    IconData icon;
    switch (mode.toUpperCase()) {
      case 'RENT':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        icon = Icons.currency_rupee;
        break;
      case 'BOTH':
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade700;
        icon = Icons.swap_horiz;
        break;
      default:
        bg = Colors.teal.shade50;
        fg = Colors.teal.shade700;
        icon = Icons.volunteer_activism;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withAlpha(60), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 3),
          Text(
            mode.toUpperCase(),
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }
}
