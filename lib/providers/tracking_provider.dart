import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/tracking_model.dart';

class TrackingProvider extends ChangeNotifier {
  final Dio _dio = DioClient.instance;

  LiveTrackingSessionModel? _currentSession;
  List<TrackingPingModel> _history = [];
  bool _isLoading = false;
  bool _isPublishing = false;
  String _errorMessage = '';

  Timer? _pollTimer;
  StreamSubscription<Position>? _positionSubscription;

  // Getters
  LiveTrackingSessionModel? get currentSession => _currentSession;
  List<TrackingPingModel> get history => _history;
  bool get isLoading => _isLoading;
  bool get isPublishing => _isPublishing;
  String get errorMessage => _errorMessage;

  // ── Fetch Current Session Info ───────────────────────────
  Future<void> fetchLatestTracking(String rentalId) async {
    try {
      final response = await _dio.get('${ApiEndpoints.tracking}/$rentalId');
      if (response.data != null && response.data['success'] == true) {
        _currentSession = LiveTrackingSessionModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        _errorMessage = '';
      } else {
        _errorMessage = response.data?['message'] ?? 'Failed to get latest location.';
      }
    } on DioException catch (e) {
      _errorMessage = DioClient.handleError(e);
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
    } finally {
      notifyListeners();
    }
  }

  // ── Fetch Ping History Trail ─────────────────────────────
  Future<void> fetchTrackingHistory(String rentalId) async {
    try {
      final response = await _dio.get('${ApiEndpoints.tracking}/$rentalId/history?limit=100');
      if (response.data != null && response.data['success'] == true) {
        final listData = response.data['data']['pings'] as List<dynamic>;
        _history = listData
            .map((item) => TrackingPingModel.fromJson(item as Map<String, dynamic>))
            .toList();
        _errorMessage = '';
      } else {
        _errorMessage = response.data?['message'] ?? 'Failed to get location history.';
      }
    } on DioException catch (e) {
      _errorMessage = DioClient.handleError(e);
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
    } finally {
      notifyListeners();
    }
  }

  // ── Start Tracking Session API ───────────────────────────
  Future<bool> startTracking(String rentalId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _dio.post('${ApiEndpoints.tracking}/$rentalId/start');
      if (response.data != null && response.data['success'] == true) {
        await fetchLatestTracking(rentalId);
        return true;
      } else {
        _errorMessage = response.data?['message'] ?? 'Failed to start tracking session.';
        return false;
      }
    } on DioException catch (e) {
      _errorMessage = DioClient.handleError(e);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Stop Tracking Session API ────────────────────────────
  Future<bool> stopTracking(String rentalId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _dio.post('${ApiEndpoints.tracking}/$rentalId/stop');
      if (response.data != null && response.data['success'] == true) {
        if (_currentSession != null && _currentSession!.rentalId == rentalId) {
          _currentSession = LiveTrackingSessionModel(
            rentalId: _currentSession!.rentalId,
            status: _currentSession!.status,
            isTrackingActive: false,
            equipmentId: _currentSession!.equipmentId,
            equipmentName: _currentSession!.equipmentName,
            equipmentCategory: _currentSession!.equipmentCategory,
            equipmentLatitude: _currentSession!.equipmentLatitude,
            equipmentLongitude: _currentSession!.equipmentLongitude,
            equipmentAddress: _currentSession!.equipmentAddress,
            renterId: _currentSession!.renterId,
            renterName: _currentSession!.renterName,
            renterPhone: _currentSession!.renterPhone,
            ownerId: _currentSession!.ownerId,
            ownerName: _currentSession!.ownerName,
            ownerPhone: _currentSession!.ownerPhone,
            latestPing: _currentSession!.latestPing,
          );
        }
        return true;
      } else {
        _errorMessage = response.data?['message'] ?? 'Failed to stop tracking session.';
        return false;
      }
    } on DioException catch (e) {
      _errorMessage = DioClient.handleError(e);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Publish GPS Ping API ─────────────────────────────────
  Future<void> publishPing(
    String rentalId, {
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
  }) async {
    try {
      final payload = {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': ?accuracy,
        'speed': ?speed,
        'heading': ?heading,
      };

      final response = await _dio.post(
        '${ApiEndpoints.tracking}/$rentalId/ping',
        data: payload,
      );

      if (response.data != null && response.data['success'] == true) {
        final newPing = TrackingPingModel.fromJson(response.data['data'] as Map<String, dynamic>);
        _history.add(newPing);
        if (_currentSession != null) {
          _currentSession = LiveTrackingSessionModel(
            rentalId: _currentSession!.rentalId,
            status: _currentSession!.status,
            isTrackingActive: _currentSession!.isTrackingActive,
            equipmentId: _currentSession!.equipmentId,
            equipmentName: _currentSession!.equipmentName,
            equipmentCategory: _currentSession!.equipmentCategory,
            equipmentLatitude: _currentSession!.equipmentLatitude,
            equipmentLongitude: _currentSession!.equipmentLongitude,
            equipmentAddress: _currentSession!.equipmentAddress,
            renterId: _currentSession!.renterId,
            renterName: _currentSession!.renterName,
            renterPhone: _currentSession!.renterPhone,
            ownerId: _currentSession!.ownerId,
            ownerName: _currentSession!.ownerName,
            ownerPhone: _currentSession!.ownerPhone,
            latestPing: newPing,
          );
        }
      }
    } catch (_) {
      // Fail silently for pings to avoid user interruption
    } finally {
      notifyListeners();
    }
  }

  // ── Polling Loop (For Viewer) ────────────────────────────
  void startPolling(String rentalId) {
    _pollTimer?.cancel();
    fetchLatestTracking(rentalId);
    fetchTrackingHistory(rentalId);

    _pollTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await fetchLatestTracking(rentalId);
      await fetchTrackingHistory(rentalId);
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ── Foreground GPS Publishing Stream (For Renter) ────────
  Future<bool> startLocationPublishing(String rentalId) async {
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
          _errorMessage = 'Location permissions are denied.';
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Location permissions are permanently denied. Please enable in settings.';
        notifyListeners();
        return false;
      }

      // 2. Start tracking session via API
      final success = await startTracking(rentalId);
      if (!success) return false;

      // 3. Obtain initial position & ping
      final initPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await publishPing(
        rentalId,
        latitude: initPos.latitude,
        longitude: initPos.longitude,
        accuracy: initPos.accuracy,
        speed: initPos.speed,
        heading: initPos.heading,
      );

      // 4. Setup periodic position subscription
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // trigger update only when moved 10 meters
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        publishPing(
          rentalId,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          speed: position.speed,
          heading: position.heading,
        );
      });

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

  Future<void> stopLocationPublishing(String rentalId) async {
    if (!_isPublishing) return;

    try {
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      await stopTracking(rentalId);
    } catch (_) {
    } finally {
      _isPublishing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopPolling();
    _positionSubscription?.cancel();
    super.dispose();
  }
}
