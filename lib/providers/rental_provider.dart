import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _errorMessage = 'Unauthorized: Please log in.';
        return;
      }
      
      final db = FirebaseFirestore.instance;
      
      final snapshot = await db.collection('rentals').where(
        Filter.or(
          Filter('renterId', isEqualTo: user.uid),
          Filter('ngoId', isEqualTo: user.uid),
          Filter('ownerId', isEqualTo: user.uid),
        )
      ).get();
      final allRentals = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return RentalModel(
          id: data['id'] ?? doc.id,
          equipmentId: data['equipmentId'] ?? '',
          renterId: data['renterId'] ?? '',
          ownerId: data['ownerId'] ?? '',
          ngoId: data['ngoId'] ?? '',
          startDate: data['startDate'] ?? '',
          expectedReturnDate: data['expectedReturnDate'] ?? '',
          status: RentalStatus.values.firstWhere(
            (e) => e.name == data['status'],
            orElse: () => RentalStatus.REQUESTED,
          ),
          agreementAccepted: data['agreementAccepted'] ?? true,
          createdAt: data['createdAt'] ?? '',
          updatedAt: data['updatedAt'] ?? '',
          renterName: data['renterName'] ?? 'Unknown Renter',
        );
      }).toList();

      _rentals = allRentals.where((r) => r.renterId == user.uid || r.ngoId == user.uid || r.ownerId == user.uid).toList();

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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _errorMessage = 'Unauthorized: Please log in.';
        return null;
      }
      final db = FirebaseFirestore.instance;
      final newDoc = db.collection('rentals').doc();
      final newRental = RentalModel(
        id: newDoc.id,
        equipmentId: equipmentId,
        renterId: user.uid,
        ownerId: '', // Ideally fetched from equipment
        ngoId: '', // Ideally fetched from equipment
        startDate: startDate.toIso8601String(),
        expectedReturnDate: endDate.toIso8601String(),
        status: RentalStatus.REQUESTED,
        agreementAccepted: agreementAccepted,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        renterName: user.displayName ?? 'Unknown',
        securityDeposit: securityDeposit ?? 0.0,
        totalAmount: totalAmount ?? 0.0,
      );
      
      await db.collection('rentals').doc(newDoc.id).set({
        'id': newRental.id,
        'equipmentId': newRental.equipmentId,
        'renterId': newRental.renterId,
        'ownerId': newRental.ownerId,
        'ngoId': newRental.ngoId,
        'startDate': newRental.startDate,
        'expectedReturnDate': newRental.expectedReturnDate,
        'status': newRental.status.name.toUpperCase(),
        'agreementAccepted': newRental.agreementAccepted,
        'createdAt': newRental.createdAt,
        'updatedAt': newRental.updatedAt,
        'renterName': newRental.renterName,
        'securityDeposit': newRental.securityDeposit,
        'totalAmount': newRental.totalAmount,
      });

      _rentals.insert(0, newRental);
      return newRental;
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
      final db = FirebaseFirestore.instance;
      await db.collection('rentals').doc(id).update({
        'status': status.toUpperCase(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final idx = _rentals.indexWhere((item) => item.id == id);
      if (idx != -1) {
        _rentals[idx] = _rentals[idx].copyWith(
          status: RentalStatus.values.firstWhere(
            (e) => e.name == status.toUpperCase(),
            orElse: () => RentalStatus.REQUESTED,
          ),
        );
      }
      return true;
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
      final db = FirebaseFirestore.instance;
      await db.collection('rentals').doc(id).delete();
      _rentals.removeWhere((item) => item.id == id);
      return true;
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
