// Emergency Alert Provider
// File: lib/providers/emergency_alert_provider.dart
//
// State management for hospital emergency alerts, NGO discovery,
// and responses.

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/utils/emergency_audio_util.dart';
import '../models/emergency_alert_model.dart';

class EmergencyAlertProvider extends ChangeNotifier {
  final Dio _dio = DioClient.instance;

  // ── State ─────────────────────────────────────────────
  List<EmergencyAlertModel> _hospitalAlerts = [];
  List<EmergencyAlertModel> _activeNgoAlerts = [];
  EmergencyAlertModel? _selectedAlert;

  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;

  // Real-time banner / alert popup event
  EmergencyAlertModel? _liveIncomingAlert;

  // ── Getters ───────────────────────────────────────────
  List<EmergencyAlertModel> get hospitalAlerts => _hospitalAlerts;
  List<EmergencyAlertModel> get activeNgoAlerts => _activeNgoAlerts;
  EmergencyAlertModel? get selectedAlert => _selectedAlert;
  EmergencyAlertModel? get liveIncomingAlert => _liveIncomingAlert;

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;

  int get activeNgoAlertsCount =>
      _activeNgoAlerts.where((a) => a.isActive).length;

  int get hospitalActiveAlertsCount =>
      _hospitalAlerts.where((a) => a.isActive).length;

  void clearLiveIncomingAlert() {
    _liveIncomingAlert = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Socket Handler for Incoming Emergency Event ───────
  Future<void> handleIncomingSocketAlert(Map<String, dynamic> data) async {
    try {
      final newAlert = EmergencyAlertModel(
        id: data['alertId']?.toString() ?? '',
        hospitalId: '',
        equipmentName: data['equipmentName']?.toString() ?? 'Equipment',
        equipmentCategory: data['equipmentCategory']?.toString(),
        quantityRequired: (data['quantityRequired'] as num?)?.toInt() ?? 1,
        priority: data['priority']?.toString().toUpperCase() ?? 'HIGH',
        status: 'ACTIVE',
        address: data['address']?.toString(),
        createdAt: data['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
        hospital: EmergencyAlertHospital(
          id: '',
          name: data['hospitalName']?.toString() ?? 'Hospital',
        ),
      );

      // Play emergency siren once if CRITICAL/HIGH
      await EmergencyAudioUtil.playEmergencyAlertTone(newAlert.id, newAlert.priority);

      _liveIncomingAlert = newAlert;

      // Prepend to NGO active list if not already present
      final index = _activeNgoAlerts.indexWhere((a) => a.id == newAlert.id);
      if (index == -1) {
        _activeNgoAlerts.insert(0, newAlert);
      }

      notifyListeners();
    } catch (_) {}
  }

  // ── Hospital: Create Alert ────────────────────────────
  Future<bool> createAlert({
    required String equipmentName,
    String? equipmentCategory,
    required int quantityRequired,
    required String priority,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? expiresAt,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = {
        'equipmentName': equipmentName.trim(),
        if (equipmentCategory != null && equipmentCategory.isNotEmpty)
          'equipmentCategory': equipmentCategory.trim(),
        'quantityRequired': quantityRequired,
        'priority': priority.toUpperCase(),
        if (description != null && description.isNotEmpty)
          'description': description.trim(),
        if (address != null && address.isNotEmpty)
          'address': address.trim(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (expiresAt != null) 'expiresAt': expiresAt.toUtc().toIso8601String(),
      };

      final response = await _dio.post(
        ApiEndpoints.emergencyAlerts,
        data: payload,
      );

      final data = response.data;
      if (data is Map && data['data'] != null) {
        final created = EmergencyAlertModel.fromJson(data['data'] as Map<String, dynamic>);
        _hospitalAlerts.insert(0, created);
        notifyListeners();
        return true;
      }

      return true;
    } on DioException catch (e) {
      _errorMessage = DioClient.handleError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  // ── Hospital: Fetch Hospital's Alerts ─────────────────
  Future<void> fetchHospitalAlerts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _dio.get(ApiEndpoints.emergencyAlertsMy);
      final data = response.data;
      if (data is Map && data['data'] is List) {
        _hospitalAlerts = (data['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((json) => EmergencyAlertModel.fromJson(json))
            .toList();
      }
    } on DioException catch (e) {
      _errorMessage = DioClient.handleError(e);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── NGO: Fetch Active Relevant Alerts ─────────────────
  Future<void> fetchActiveAlerts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _dio.get(ApiEndpoints.emergencyAlerts);
      final data = response.data;
      if (data is Map && data['data'] is List) {
        _activeNgoAlerts = (data['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((json) => EmergencyAlertModel.fromJson(json))
            .toList();
      }
    } on DioException catch (e) {
      _errorMessage = DioClient.handleError(e);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Shared: Fetch Alert Details ───────────────────────
  Future<EmergencyAlertModel?> fetchAlertDetails(String alertId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Acknowledged by viewing details
      EmergencyAudioUtil.stopEmergencyAlertTone();

      final response = await _dio.get('${ApiEndpoints.emergencyAlerts}/$alertId');
      final data = response.data;
      if (data is Map && data['data'] != null) {
        final alert = EmergencyAlertModel.fromJson(data['data'] as Map<String, dynamic>);
        _selectedAlert = alert;
        notifyListeners();
        return alert;
      }
      return null;
    } on DioException catch (e) {
      _errorMessage = DioClient.handleError(e);
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Hospital: Update Alert Status ─────────────────────
  Future<bool> updateAlertStatus(String alertId, String status) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _dio.patch(
        '${ApiEndpoints.emergencyAlerts}/$alertId/status',
        data: {'status': status.toUpperCase()},
      );

      final data = response.data;
      if (data is Map && data['data'] != null) {
        final updated = EmergencyAlertModel.fromJson(data['data'] as Map<String, dynamic>);

        final index = _hospitalAlerts.indexWhere((a) => a.id == alertId);
        if (index != -1) {
          _hospitalAlerts[index] = updated;
        }
        if (_selectedAlert?.id == alertId) {
          _selectedAlert = updated;
        }

        notifyListeners();
        return true;
      }
      return true;
    } on DioException catch (e) {
      _errorMessage = DioClient.handleError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  // ── NGO: Respond to Alert ─────────────────────────────
  Future<bool> respondToAlert({
    required String alertId,
    required int quantityAvailable,
    String? message,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _dio.post(
        '${ApiEndpoints.emergencyAlerts}/$alertId/respond',
        data: {
          'quantityAvailable': quantityAvailable,
          if (message != null && message.isNotEmpty) 'message': message.trim(),
        },
      );

      final data = response.data;
      if (data is Map && data['data'] != null) {
        final myResponse = EmergencyAlertResponseModel.fromJson(
          data['data'] as Map<String, dynamic>,
        );

        // Update active list locally
        final index = _activeNgoAlerts.indexWhere((a) => a.id == alertId);
        if (index != -1) {
          final old = _activeNgoAlerts[index];
          _activeNgoAlerts[index] = EmergencyAlertModel(
            id: old.id,
            hospitalId: old.hospitalId,
            equipmentName: old.equipmentName,
            equipmentCategory: old.equipmentCategory,
            quantityRequired: old.quantityRequired,
            description: old.description,
            priority: old.priority,
            status: data['alertStatus']?.toString().toUpperCase() ?? old.status,
            address: old.address,
            latitude: old.latitude,
            longitude: old.longitude,
            expiresAt: old.expiresAt,
            createdAt: old.createdAt,
            hospital: old.hospital,
            totalAvailable: (data['totalAvailable'] as num?)?.toInt() ?? old.totalAvailable,
            responseCount: old.responseCount + 1,
            myResponse: myResponse,
          );
        }

        // Refresh selected alert if open
        if (_selectedAlert?.id == alertId) {
          await fetchAlertDetails(alertId);
        }

        notifyListeners();
        return true;
      }
      return true;
    } on DioException catch (e) {
      _errorMessage = DioClient.handleError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  // ── NGO: Update Response ──────────────────────────────
  Future<bool> updateResponse({
    required String alertId,
    int? quantityAvailable,
    String? message,
    String? status,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _dio.patch(
        '${ApiEndpoints.emergencyAlerts}/$alertId/respond',
        data: {
          if (quantityAvailable != null) 'quantityAvailable': quantityAvailable,
          if (message != null) 'message': message.trim(),
          if (status != null) 'status': status.toUpperCase(),
        },
      );

      final data = response.data;
      if (data is Map && data['data'] != null) {
        if (_selectedAlert?.id == alertId) {
          await fetchAlertDetails(alertId);
        }
        await fetchActiveAlerts();
        return true;
      }
      return true;
    } on DioException catch (e) {
      _errorMessage = DioClient.handleError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }
}
