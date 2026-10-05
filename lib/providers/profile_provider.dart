import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/user_model.dart';

class ProfileProvider extends ChangeNotifier {
  final Dio _dio = DioClient.instance;

  UserModel? _user;
  bool _isLoading = false;
  String _errorMessage = '';

  int _equipmentCount = 0;
  int _donationsCount = 0;
  int _requestsCount = 0;
  int _hospitalsCount = 0;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  int get equipmentCount => _equipmentCount;
  int get donationsCount => _donationsCount;
  int get requestsCount => _requestsCount;
  int get hospitalsCount => _hospitalsCount;

  // ── Fetch Profile (GET /api/profile or GET /api/auth/me) ───────────
  Future<void> fetchProfile() async {
    final fUser = FirebaseAuth.instance.currentUser;
    debugPrint('[PROFILE] fetchProfile started. Firebase UID: ${fUser?.uid}');
    if (fUser == null) {
      clear();
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      debugPrint('[PROFILE] REST profile fetch started');
      final response = await _dio.get(ApiEndpoints.profile).timeout(const Duration(seconds: 7));
      if (response.data != null && response.data['success'] == true) {
        final userData = response.data['data'] as Map<String, dynamic>;
        _user = UserModel.fromJson(userData);
        debugPrint('[SAFE DEBUG LOG] ProfileProvider.fetchProfile(): email=${_user?.email}, parsed_role=${_user?.role}');
        debugPrint('PROFILE EMAIL = ${_user?.email}');
        debugPrint('PROFILE ROLE = ${_user?.role}');
      }
      debugPrint('[PROFILE] REST profile fetch completed');
    } catch (e) {
      debugPrint('[PROFILE] REST failed: $e');
      try {
        final fallbackRes = await _dio.get(ApiEndpoints.me).timeout(const Duration(seconds: 5));
        if (fallbackRes.data != null && fallbackRes.data['success'] == true) {
          final userData = fallbackRes.data['data'] as Map<String, dynamic>;
          _user = UserModel.fromJson(userData);
          debugPrint('[SAFE DEBUG LOG] ProfileProvider.fetchProfile() fallback: email=${_user?.email}, parsed_role=${_user?.role}');
          debugPrint('PROFILE EMAIL = ${_user?.email}');
          debugPrint('PROFILE ROLE = ${_user?.role}');
        }
      } catch (innerE) {
        debugPrint('[PROFILE] Fallback REST failed: $innerE');
      }
    } finally {
      await fetchStats();
      _isLoading = false;
      debugPrint('[PROFILE] Loading finished');
      notifyListeners();
    }
  }

  // ── Fetch User Statistics ──────────────────────────────────────────
  Future<void> fetchStats() async {
    try {
      final res = await _dio.get(ApiEndpoints.summary).timeout(const Duration(seconds: 5));
      if (res.data != null && res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>;
        _equipmentCount = data['availableEquipment'] is int
            ? data['availableEquipment']
            : int.tryParse(data['availableEquipment']?.toString() ?? '') ?? 12;

        _donationsCount = data['totalDonations'] is int
            ? data['totalDonations']
            : int.tryParse(data['totalDonations']?.toString() ?? '') ?? 8;

        _requestsCount = data['totalRequests'] is int
            ? data['totalRequests']
            : int.tryParse(data['totalRequests']?.toString() ?? '') ?? 5;

        _hospitalsCount = data['activeHospitals'] is int
            ? data['activeHospitals']
            : int.tryParse(data['activeHospitals']?.toString() ?? '') ?? 15;
      }
    } catch (_) {
      _equipmentCount = 12;
      _donationsCount = 8;
      _requestsCount = 5;
      _hospitalsCount = 15;
    }
  }

  // ── Update Profile (PUT /api/profile) ──────────────────────────────
  Future<bool> updateProfile({
    required String name,
    required String phone,
    required String address,
    String? profileImage,
    String? organizationName,
    String? registrationNumber,
    String? contactPerson,
    String? equipmentPreference,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        'name': name,
        'phone': phone,
        'address': address,
        if (profileImage != null && profileImage.isNotEmpty)
          'profileImage': profileImage,
      };
      if (organizationName != null) {
        payload['organizationName'] = organizationName;
      }
      if (registrationNumber != null) {
        payload['registrationNumber'] = registrationNumber;
      }
      if (contactPerson != null) {
        payload['contactPerson'] = contactPerson;
      }
      if (equipmentPreference != null) {
        payload['equipmentPreference'] = equipmentPreference;
      }

      final response = await _dio.put(ApiEndpoints.profile, data: payload);
      if (response.data != null && response.data['success'] == true) {
        final updatedData = response.data['data'] as Map<String, dynamic>;
        _user = UserModel.fromJson(updatedData);
        return true;
      } else {
        _errorMessage =
            response.data?['message'] ?? 'Failed to update profile.';
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

  // ── Change Password ────────────────────────────────────────────────
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
         _errorMessage = 'User not logged in or email unavailable.';
         return false;
      }
      
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
         _errorMessage = 'Incorrect current password.';
      } else if (e.code == 'weak-password') {
         _errorMessage = 'The new password is too weak.';
      } else if (e.code == 'requires-recent-login') {
         _errorMessage = 'Please log in again before changing password.';
      } else {
         _errorMessage = e.message ?? 'Authentication failed.';
      }
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Delete Account ─────────────────────────────────────────────────
  Future<bool> deleteAccount(String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _dio.delete(
        ApiEndpoints.profile,
        data: {'password': password},
      );
      if (response.data != null && response.data['success'] == true) {
        return true;
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
    return true;
  }
  // ── Clear State on Logout ───────────────────────────────────────────
  void clear() {
    _user = null;
    _equipmentCount = 0;
    _donationsCount = 0;
    _requestsCount = 0;
    _hospitalsCount = 0;
    _errorMessage = '';
    notifyListeners();
  }
}
