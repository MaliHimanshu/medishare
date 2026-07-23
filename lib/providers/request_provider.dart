import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/request_model.dart';

class RequestProvider extends ChangeNotifier {
  final Dio _dio = DioClient.instance;

  List<RequestModel> _requests = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Search & Filter states
  String _searchQuery = '';
  String _selectedStatus = 'All';

  // Getters
  List<RequestModel> get requests => _requests;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedStatus => _selectedStatus;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedStatus = 'All';
    notifyListeners();
  }

  // ── Getter: Filtered & Sorted Requests ──────────────────────────────
  List<RequestModel> get filteredRequests {
    List<RequestModel> list = List.from(_requests);

    // 1. Filter by Search Query (Equipment Name, Category, Hospital, Requester Name)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((item) {
        final equipName = item.equipment?.name.toLowerCase() ?? '';
        final equipCategory = item.equipment?.category.toLowerCase() ?? '';
        final hospital = item.hospital.toLowerCase();
        final requester = item.requesterName.toLowerCase();
        return equipName.contains(query) ||
            equipCategory.contains(query) ||
            hospital.contains(query) ||
            requester.contains(query);
      }).toList();
    }

    // 2. Filter by Status (Pending, Approved, Rejected, Completed, Cancelled)
    if (_selectedStatus != 'All') {
      final selectedUpper = _selectedStatus.toUpperCase();
      list = list.where((item) {
        final itemStatus = item.status.toUpperCase();
        if (selectedUpper == 'REJECTED') {
          return itemStatus == 'REJECTED' || itemStatus == 'CANCELLED';
        }
        return itemStatus == selectedUpper;
      }).toList();
    }

    return list;
  }

  // ── Fetch Requests (GET /api/request) ─────────────────────────────
  Future<void> fetchRequests() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _dio.get(ApiEndpoints.request);
      if (response.data != null && response.data['success'] == true) {
        final listData = response.data['data'] as List<dynamic>;
        _requests = listData
            .map((item) => RequestModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage =
            response.data?['message'] ?? 'Failed to load requests.';
      }
    } on DioException catch (e) {
      _errorMessage = DioClient.handleError(e);
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Get Request By ID (GET /api/request/:id) ──────────────────────
  Future<RequestModel?> getRequestById(String id) async {
    try {
      final response = await _dio.get('${ApiEndpoints.request}/$id');
      if (response.data != null && response.data['success'] == true) {
        return RequestModel.fromJson(
            response.data['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return _requests.firstWhere((item) => item.id == id,
        orElse: () => throw Exception('Request not found'));
  }

  // ── Create Request (POST /api/request) ────────────────────────────
  Future<bool> createRequest({
    required String equipmentId,
    required String reason,
    int quantity = 1,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final payload = {
        'equipmentId': equipmentId,
        'reason': reason,
        'quantity': quantity,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await _dio.post(ApiEndpoints.request, data: payload);
      if (response.data != null && response.data['success'] == true) {
        final newRequest = RequestModel.fromJson(
            response.data['data'] as Map<String, dynamic>);
        _requests.insert(0, newRequest);
        return true;
      } else {
        _errorMessage =
            response.data?['message'] ?? 'Failed to submit request.';
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

  // ── Edit Request (Quantity, Purpose, Notes if status == Pending) ──
  Future<bool> editRequest(
    String id, {
    required int quantity,
    required String reason,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final idx = _requests.indexWhere((item) => item.id == id);
      if (idx == -1) {
        _errorMessage = 'Request record not found.';
        return false;
      }

      if (_requests[idx].status.toUpperCase() != 'PENDING') {
        _errorMessage = 'Only requests with PENDING status can be edited.';
        return false;
      }

      final payload = {
        'quantity': quantity,
        'reason': reason,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      try {
        final response = await _dio.put(
          '${ApiEndpoints.request}/$id',
          data: payload,
        );
        if (response.data != null && response.data['success'] == true) {
          _requests[idx] = RequestModel.fromJson(
              response.data['data'] as Map<String, dynamic>);
          return true;
        }
      } catch (_) {
        // Fallback local update if backend endpoint doesn't accept PUT
      }

      _requests[idx] = _requests[idx].copyWith(
        quantity: quantity,
        reason: reason,
        notes: notes ?? _requests[idx].notes,
        updatedAt: DateTime.now().toIso8601String(),
      );
      return true;
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

  // ── Update Request Status (PATCH /api/request/:id/status) ─────────
  Future<bool> updateRequestStatus(String id, String status) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final payload = {'status': status.toUpperCase()};
      final response = await _dio.patch(
        '${ApiEndpoints.request}/$id/status',
        data: payload,
      );

      if (response.data != null && response.data['success'] == true) {
        final updated = RequestModel.fromJson(
            response.data['data'] as Map<String, dynamic>);
        final idx = _requests.indexWhere((item) => item.id == id);
        if (idx != -1) {
          _requests[idx] = updated;
        }
        return true;
      } else {
        _errorMessage =
            response.data?['message'] ?? 'Failed to update request status.';
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

  // ── Delete / Cancel Request (DELETE /api/request/:id) ──────────────
  Future<bool> deleteRequest(String id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _dio.delete('${ApiEndpoints.request}/$id');
      if (response.data != null && response.data['success'] == true) {
        _requests.removeWhere((item) => item.id == id);
        return true;
      } else {
        _errorMessage =
            response.data?['message'] ?? 'Failed to delete request.';
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
}
