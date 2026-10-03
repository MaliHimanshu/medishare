import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../models/tracking_model.dart';
import '../services/location_service.dart';

class TrackingProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  LiveTrackingSessionModel? _currentSession;
  List<TrackingPingModel> _history = [];
  bool _isLoading = false;
  bool _isPublishing = false;
  String _errorMessage = '';

  StreamSubscription<DocumentSnapshot>? _deliverySubscription;
  StreamSubscription<QuerySnapshot>? _historySubscription;
  String? _activeDeliveryId;

  // Getters
  LiveTrackingSessionModel? get currentSession => _currentSession;
  List<TrackingPingModel> get history => _history;
  bool get isLoading => _isLoading;
  bool get isPublishing => _isPublishing;
  String get errorMessage => _errorMessage;

  Future<String?> _getDeliveryIdForRental(String rentalId) async {
    try {

      final snapshot = await _db.collection('deliveries')
          .where('rentalId', isEqualTo: rentalId)
          .where('status', isEqualTo: 'IN_TRANSIT')
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      
      // Fallback: any delivery for this rental
      final anySnapshot = await _db.collection('deliveries')
          .where('rentalId', isEqualTo: rentalId)
          .limit(1)
          .get();
      if (anySnapshot.docs.isNotEmpty) {
        return anySnapshot.docs.first.id;
      }
    } catch (e) {
      _errorMessage = 'Error finding delivery: $e';
    }
    return null;
  }

  // ── Polling Loop (For Viewer/Recipient) ────────────────────────────
  void startPolling(String rentalId) async {
    _isLoading = true;
    notifyListeners();

    _activeDeliveryId = await _getDeliveryIdForRental(rentalId);
    if (_activeDeliveryId == null) {
      _errorMessage = 'No active delivery found for this rental.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _deliverySubscription?.cancel();
    _deliverySubscription = _db.collection('deliveries').doc(_activeDeliveryId).snapshots().listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['currentLatitude'] != null && data['currentLongitude'] != null) {
          final ping = TrackingPingModel(
            id: 'latest',
            latitude: data['currentLatitude'],
            longitude: data['currentLongitude'],
            accuracy: 10.0,
            speed: 0.0,
            heading: 0.0,
            recordedAt: DateTime.tryParse(data['lastLocationUpdate'] ?? '') ?? DateTime.now(),
          );

          _currentSession = LiveTrackingSessionModel(
            rentalId: rentalId,
            status: data['status'] ?? 'UNKNOWN',
            isTrackingActive: data['status'] == 'IN_TRANSIT',
            equipmentId: '',
            equipmentName: '',
            equipmentCategory: '',
            equipmentLatitude: 0,
            equipmentLongitude: 0,
            equipmentAddress: '',
            renterId: '',
            renterName: '',
            renterPhone: '',
            ownerId: '',
            ownerName: '',
            ownerPhone: '',
            latestPing: ping,
          );
          
          // Basic history
          if (_history.isEmpty || _history.last.recordedAt != ping.recordedAt) {
             _history.add(ping);
          }
          
          _errorMessage = '';
          _isLoading = false;
          notifyListeners();
        }
      }
    }, onError: (e) {
      _errorMessage = 'Live location temporarily unavailable: $e';
      notifyListeners();
    });
  }

  void stopPolling() {
    _deliverySubscription?.cancel();
    _deliverySubscription = null;
  }

  // ── Foreground GPS Publishing Stream (For Delivery Partner) ────────
  Future<bool> startLocationPublishing(String deliveryId) async {
    if (_isPublishing) return true;

    try {
      // 1. Permission checks
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Location services are disabled. Please enable GPS.';
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Location permission is required.';
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Location permissions are permanently denied.';
        notifyListeners();
        return false;
      }

      // 2. Start tracking service
      await _locationService.startTracking(deliveryId);

      _isPublishing = true;
      _errorMessage = '';
      return true;
    } catch (e) {
      _errorMessage = 'Failed to start GPS publishing: $e';
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> stopLocationPublishing(String deliveryId) async {
    if (!_isPublishing) return;
    try {
      _locationService.stopTracking();
    } catch (_) {
    } finally {
      _isPublishing = false;
      notifyListeners();
    }
  }

  // Backward compatible stubs for live_tracking_screen
  Future<void> fetchLatestTracking(String rentalId) async {}
  Future<void> fetchTrackingHistory(String rentalId) async {}

  // ── Clear State on Logout ───────────────────────────────────────────
  void clear() {
    stopPolling();
    _locationService.stopTracking();
    _currentSession = null;
    _history = [];
    _errorMessage = '';
    _activeDeliveryId = null;
    _isPublishing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    _locationService.stopTracking();
    super.dispose();
  }
}
