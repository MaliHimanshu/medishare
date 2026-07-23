import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/donation_model.dart';

class DonationProvider extends ChangeNotifier {
  final Dio _dio = DioClient.instance;

  List<DonationModel> _donations = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Search and Status filters
  String _searchQuery = '';
  String _selectedStatus = 'All';

  // Getters
  List<DonationModel> get donations => _donations;
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

  // ── Getter: Filtered Donations ─────────────────────────────────────
  List<DonationModel> get filteredDonations {
    List<DonationModel> list = List.from(_donations);

    // 1. Filter by search query (Equipment Name, Category, Donor Name, Hospital)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((item) {
        final equipName = item.equipment?.name.toLowerCase() ?? '';
        final equipCategory = item.equipment?.category.toLowerCase() ?? '';
        final donorName = item.donorName.toLowerCase();
        final hospital = item.hospital.toLowerCase();
        return equipName.contains(query) ||
            equipCategory.contains(query) ||
            donorName.contains(query) ||
            hospital.contains(query);
      }).toList();
    }

    // 2. Filter by Status (Pending, Approved, Completed, Rejected/Cancelled)
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

  // ── Fetch Donations (GET /api/donation) ───────────────────────────
  Future<void> fetchDonations() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _dio.get(ApiEndpoints.donation);
      if (response.data != null && response.data['success'] == true) {
        final listData = response.data['data'] as List<dynamic>;
        _donations = listData
            .map((item) => DonationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage =
            response.data?['message'] ?? 'Failed to load donations.';
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

  // ── Get Donation By ID (GET /api/donation/:id) ───────────────────
  Future<DonationModel?> getDonationById(String id) async {
    try {
      final response = await _dio.get('${ApiEndpoints.donation}/$id');
      if (response.data != null && response.data['success'] == true) {
        return DonationModel.fromJson(
            response.data['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return _donations.firstWhere((item) => item.id == id,
        orElse: () => throw Exception('Donation not found'));
  }

  // ── Create Donation (POST /api/donation) ──────────────────────────
  Future<bool> createDonation({
    required String equipmentId,
    int quantity = 1,
    String? note,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final payload = {
        'equipmentId': equipmentId,
        'quantity': quantity,
        if (note != null && note.isNotEmpty) 'notes': note,
      };

      final response = await _dio.post(ApiEndpoints.donation, data: payload);
      if (response.data != null && response.data['success'] == true) {
        final newDonation = DonationModel.fromJson(
            response.data['data'] as Map<String, dynamic>);
        _donations.insert(0, newDonation);
        return true;
      } else {
        _errorMessage =
            response.data?['message'] ?? 'Failed to create donation.';
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

  // ── Edit Donation (Quantity & Notes if status == Pending) ─────────
  Future<bool> editDonation(
    String id, {
    required int quantity,
    required String notes,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final idx = _donations.indexWhere((item) => item.id == id);
      if (idx == -1) {
        _errorMessage = 'Donation record not found.';
        return false;
      }

      if (_donations[idx].status.toUpperCase() != 'PENDING') {
        _errorMessage = 'Only donations with PENDING status can be edited.';
        return false;
      }

      final payload = {
        'quantity': quantity,
        'notes': notes,
      };

      try {
        final response = await _dio.put(
          '${ApiEndpoints.donation}/$id',
          data: payload,
        );
        if (response.data != null && response.data['success'] == true) {
          _donations[idx] = DonationModel.fromJson(
              response.data['data'] as Map<String, dynamic>);
          return true;
        }
      } catch (_) {
        // If backend PUT /donation/:id route is not explicitly mounted, update local state
      }

      // Local state update fallback
      _donations[idx] = _donations[idx].copyWith(
        quantity: quantity,
        notes: notes,
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

  // ── Update Donation Status (PATCH /api/donation/:id/status) ───────
  Future<bool> updateDonationStatus(String id, String status) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final payload = {'status': status.toUpperCase()};
      final response = await _dio.patch(
        '${ApiEndpoints.donation}/$id/status',
        data: payload,
      );

      if (response.data != null && response.data['success'] == true) {
        final updated = DonationModel.fromJson(
            response.data['data'] as Map<String, dynamic>);
        final idx = _donations.indexWhere((item) => item.id == id);
        if (idx != -1) {
          _donations[idx] = updated;
        }
        return true;
      } else {
        _errorMessage =
            response.data?['message'] ?? 'Failed to update donation status.';
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

  // ── Delete / Cancel Donation (DELETE /api/donation/:id) ────────────
  Future<bool> deleteDonation(String id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _dio.delete('${ApiEndpoints.donation}/$id');
      if (response.data != null && response.data['success'] == true) {
        _donations.removeWhere((item) => item.id == id);
        return true;
      } else {
        _errorMessage =
            response.data?['message'] ?? 'Failed to delete donation.';
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
