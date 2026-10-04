import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/rental_model.dart';

class RentalProvider extends ChangeNotifier {
  final Dio _dio = DioClient.instance;

  List<RentalModel> _rentals = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Search & Filter states
  String _searchQuery = '';
  String _selectedStatus = 'All';

  // Getters
  List<RentalModel> get rentals => _rentals;
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

  // ── Getter: Filtered & Sorted Rentals ──────────────────────────────
  List<RentalModel> get filteredRentals {
    List<RentalModel> list = List.from(_rentals);

    // 1. Filter by Search Query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((item) {
        final equipName = item.equipment?.name.toLowerCase() ?? '';
        final equipCategory = item.equipment?.category.toLowerCase() ?? '';
        final renter = item.renterName.toLowerCase();
        return equipName.contains(query) ||
            equipCategory.contains(query) ||
            renter.contains(query);
      }).toList();
    }

    // 2. Filter by Status (Pending, Approved, Active, Returned, Cancelled, Rejected)
    if (_selectedStatus != 'All') {
      final selectedUpper = _selectedStatus.toUpperCase();
      list = list.where((item) {
        final itemStatus = item.status.name.toUpperCase();
        return itemStatus == selectedUpper;
      }).toList();
    }

    return list;
  }

  // ── Fetch Rentals (GET /api/rental) ──────────────────────────────
  Future<void> fetchRentals() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _dio.get(ApiEndpoints.rental);

      if (response.data != null && response.data['success'] == true) {
        final List rawList = response.data['data'] ?? [];
        _rentals = rawList
            .map((json) => RentalModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        final rawMsg = response.data?['message']?.toString();
        _errorMessage = (rawMsg != null && rawMsg != 'undefined' && rawMsg.trim().isNotEmpty)
            ? rawMsg
            : 'Failed to fetch rentals.';
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

  // ── Create Rental (POST /api/rental) ─────────────────────────────
  Future<RentalModel?> createRental({
    required String equipmentId,
    required DateTime startDate,
    required DateTime endDate,
    double? rentalPricePerDay,
    double? securityDeposit,
    double? totalAmount,
    bool agreementAccepted = true,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final payload = {
        'equipmentId': equipmentId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

      final response = await _dio.post(
        ApiEndpoints.rental,
        data: payload,
      );

      if (response.data != null && response.data['success'] == true) {
        final newRental = RentalModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        _rentals.insert(0, newRental);
        return newRental;
      } else {
        final rawMsg = response.data?['message']?.toString();
        _errorMessage = (rawMsg != null && rawMsg != 'undefined' && rawMsg.trim().isNotEmpty)
            ? rawMsg
            : 'Failed to create rental request.';
        return null;
      }
    } on DioException catch (e) {
      _errorMessage = DioClient.handleError(e);
      return null;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Update Rental Status (PATCH /api/rental/:id/status) ──────────
  Future<bool> updateRentalStatus(String id, String status) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _dio.patch(
        '${ApiEndpoints.rental}/$id/status',
        data: {'status': status.toUpperCase()},
      );

      if (response.data != null && response.data['success'] == true) {
        final updatedRental = RentalModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        final idx = _rentals.indexWhere((item) => item.id == id);
        if (idx != -1) {
          _rentals[idx] = updatedRental;
        }
        return true;
      } else {
        _errorMessage =
            response.data?['message'] ?? 'Failed to update rental status.';
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

  // ── Delete Rental (DELETE /api/rental/:id) ───────────────────────
  Future<bool> deleteRental(String id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _dio.delete('${ApiEndpoints.rental}/$id');

      if (response.data != null && response.data['success'] == true) {
        _rentals.removeWhere((item) => item.id == id);
        return true;
      } else {
        _errorMessage =
            response.data?['message'] ?? 'Failed to delete rental.';
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

  // ══════════════════════════════════════════════════════════
  // ── Razorpay Payment Methods ──────────────────────────────
  // ══════════════════════════════════════════════════════════

  // ── 1. Create Razorpay Order (POST /api/rental/:id/create-order) ──
  Future<Map<String, dynamic>?> createPaymentOrder(String rentalId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _dio.post(
        '${ApiEndpoints.rental}/$rentalId/create-order',
      );

      if (response.data != null && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        final rawMsg = response.data?['message']?.toString();
        _errorMessage = (rawMsg != null && rawMsg != 'undefined' && rawMsg.trim().isNotEmpty)
            ? rawMsg
            : 'Failed to create payment order.';
        return null;
      }
    } on DioException catch (e) {
      _errorMessage = DioClient.handleError(e);
      return null;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── 2. Verify Payment (POST /api/rental/:id/verify-payment) ──────
  Future<bool> verifyPayment({
    required String rentalId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final payload = {
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      };

      final response = await _dio.post(
        '${ApiEndpoints.rental}/$rentalId/verify-payment',
        data: payload,
      );

      if (response.data != null && response.data['success'] == true) {
        final updatedRental = RentalModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        final idx = _rentals.indexWhere((r) => r.id == rentalId);
        if (idx != -1) {
          _rentals[idx] = updatedRental;
        }
        return true;
      } else {
        _errorMessage =
            response.data?['message'] ?? 'Payment verification failed.';
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

  // ── 3. Record Payment Failure (POST /api/rental/:id/payment-failed)
  Future<void> recordPaymentFailure(String rentalId) async {
    try {
      await _dio.post('${ApiEndpoints.rental}/$rentalId/payment-failed');
      final idx = _rentals.indexWhere((r) => r.id == rentalId);
      if (idx != -1) {
        _rentals[idx] = _rentals[idx].copyWith(paymentStatus: 'FAILED');
        notifyListeners();
      }
    } catch (_) {}
  }
  // ── Clear State on Logout ───────────────────────────────────────────
  void clear() {
    _rentals = [];
    _errorMessage = '';
    _searchQuery = '';
    notifyListeners();
  }
}
