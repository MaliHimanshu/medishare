import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/equipment_model.dart';

class DashboardProvider extends ChangeNotifier {
  final Dio _dio = DioClient.instance;

  // ── Loading States ────────────────────────────────────
  bool _isLoadingSummary = false;
  bool _isLoadingRequests = false;
  bool _isLoadingDonations = false;
  bool _isLoadingNotifications = false;
  bool _isLoadingHospitals = false;
  bool _isLoadingEquipment = false;

  // ── Data Fields ───────────────────────────────────────
  Map<String, dynamic>? _summary;
  List<dynamic> _recentRequests = [];
  List<dynamic> _recentDonations = [];
  List<dynamic> _notifications = [];
  List<dynamic> _hospitals = [];
  List<EquipmentModel> _equipmentList = [];

  // ── Getters ───────────────────────────────────────────
  bool get isLoadingSummary => _isLoadingSummary;
  bool get isLoadingRequests => _isLoadingRequests;
  bool get isLoadingDonations => _isLoadingDonations;
  bool get isLoadingNotifications => _isLoadingNotifications;
  bool get isLoadingHospitals => _isLoadingHospitals;
  bool get isLoadingEquipment => _isLoadingEquipment;

  Map<String, dynamic>? get summary => _summary;
  List<dynamic> get recentRequests => _recentRequests;
  List<dynamic> get recentDonations => _recentDonations;
  List<dynamic> get notifications => _notifications;
  List<dynamic> get hospitals => _hospitals;
  List<EquipmentModel> get equipmentList => _equipmentList;

  // ── Fetch All Dashboard Data ──────────────────────────
  Future<void> fetchAll() async {
    await Future.wait([
      fetchSummary(),
      fetchRecentRequests(),
      fetchRecentDonations(),
      fetchNotifications(),
      fetchHospitals(),
      fetchEquipment(),
    ]);
  }

  // ── Fetch Summary Counters ────────────────────────────
  Future<void> fetchSummary() async {
    _isLoadingSummary = true;
    notifyListeners();
    try {
      final response = await _dio.get(ApiEndpoints.summary);
      final rawData = response.data;
      if (rawData is Map &&
          rawData['success'] == true &&
          rawData['data'] is Map) {
        _summary = Map<String, dynamic>.from(rawData['data'] as Map);
      }
    } catch (e) {
      DioClient.debugLog('fetchSummary error: $e');
    } finally {
      _isLoadingSummary = false;
      notifyListeners();
    }
  }

  // ── Fetch Recent Requests ─────────────────────────────
  Future<void> fetchRecentRequests() async {
    _isLoadingRequests = true;
    notifyListeners();
    try {
      final response = await _dio.get(ApiEndpoints.recentRequests);
      final rawData = response.data;
      if (rawData is Map && rawData['success'] == true) {
        final listData = rawData['data'];
        _recentRequests = listData is List ? listData : <dynamic>[];
      } else if (rawData is List) {
        _recentRequests = rawData;
      } else {
        _recentRequests = <dynamic>[];
      }
    } catch (e) {
      DioClient.debugLog('fetchRecentRequests error: $e');
    } finally {
      _isLoadingRequests = false;
      notifyListeners();
    }
  }

  // ── Fetch Recent Donations ────────────────────────────
  Future<void> fetchRecentDonations() async {
    _isLoadingDonations = true;
    notifyListeners();
    try {
      final response = await _dio.get(ApiEndpoints.recentDonations);
      final rawData = response.data;
      if (rawData is Map && rawData['success'] == true) {
        final listData = rawData['data'];
        _recentDonations = listData is List ? listData : <dynamic>[];
      } else if (rawData is List) {
        _recentDonations = rawData;
      } else {
        _recentDonations = <dynamic>[];
      }
    } catch (e) {
      DioClient.debugLog('fetchRecentDonations error: $e');
    } finally {
      _isLoadingDonations = false;
      notifyListeners();
    }
  }

  // ── Fetch Notifications ───────────────────────────────
  Future<void> fetchNotifications() async {
    _isLoadingNotifications = true;
    notifyListeners();
    try {
      final response = await _dio.get(ApiEndpoints.notifications);
      final rawData = response.data;
      if (rawData is Map) {
        if (rawData['notifications'] is List) {
          _notifications = rawData['notifications'] as List<dynamic>;
        } else if (rawData['data'] is List) {
          _notifications = rawData['data'] as List<dynamic>;
        } else {
          _notifications = <dynamic>[];
        }
      } else if (rawData is List) {
        _notifications = rawData;
      } else {
        _notifications = <dynamic>[];
      }
    } catch (e) {
      DioClient.debugLog('fetchNotifications error: $e');
    } finally {
      _isLoadingNotifications = false;
      notifyListeners();
    }
  }

  // ── Fetch Hospitals ───────────────────────────────────
  Future<void> fetchHospitals({String? search}) async {
    _isLoadingHospitals = true;
    notifyListeners();
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      final response = await _dio.get(
        ApiEndpoints.hospital,
        queryParameters: queryParams,
      );
      final rawData = response.data;
      if (rawData is Map && rawData['success'] == true) {
        final listData = rawData['hospitals'] ?? rawData['data'];
        _hospitals = listData is List ? listData : <dynamic>[];
      } else if (rawData is List) {
        _hospitals = rawData;
      } else {
        _hospitals = <dynamic>[];
      }
    } catch (e) {
      DioClient.debugLog('fetchHospitals error: $e');
    } finally {
      _isLoadingHospitals = false;
      notifyListeners();
    }
  }

  // ── Fetch Equipment List ──────────────────────────────
  Future<void> fetchEquipment() async {
    _isLoadingEquipment = true;
    notifyListeners();
    try {
      final response = await _dio.get(ApiEndpoints.equipment);
      final rawData = response.data;
      List<dynamic> list = <dynamic>[];
      if (rawData is Map && rawData['success'] == true) {
        final listData = rawData['data'];
        list = listData is List ? listData : <dynamic>[];
      } else if (rawData is List) {
        list = rawData;
      }
      _equipmentList = list
          .whereType<Map<String, dynamic>>()
          .map((item) => EquipmentModel.fromJson(item))
          .toList();
    } catch (e) {
      DioClient.debugLog('fetchEquipment error: $e');
    } finally {
      _isLoadingEquipment = false;
      notifyListeners();
    }
  }

  // ── Mark Notification as Read ──────────────────────────
  Future<void> markNotificationRead(String id) async {
    try {
      await _dio.patch('/notification/$id/read');
      // Update local status
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        final item = Map<String, dynamic>.from(_notifications[index] as Map);
        item['isRead'] = true;
        _notifications[index] = item;
        notifyListeners();
      }
    } catch (e) {
      DioClient.debugLog('markNotificationRead error: $e');
    }
  }

  // ── Delete Notification ───────────────────────────────
  Future<void> deleteNotification(String id) async {
    try {
      await _dio.delete('/notification/$id');
      _notifications.removeWhere((n) => n['id'] == id);
      notifyListeners();
    } catch (e) {
      DioClient.debugLog('deleteNotification error: $e');
    }
  }
}
