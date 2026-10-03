import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;
  Function(Position)? onLocationChanged;
  
  // Singleton pattern for centralized location tracking
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are disabled. Please enable the services
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      return false;
    }
    return true;
  }

  Future<void> startTracking(String deliveryId) async {
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) return;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position? position) {
      if (position != null) {
        // Write to Firestore deliveries collection
        FirebaseFirestore.instance.collection('deliveries').doc(deliveryId).update({
          'currentLatitude': position.latitude,
          'currentLongitude': position.longitude,
          'lastLocationUpdate': position.timestamp.toIso8601String(),
        }).catchError((e) {
          // Silent catch for background failures
        });

        if (onLocationChanged != null) {
          onLocationChanged!(position);
        }
      }
    });
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
}
