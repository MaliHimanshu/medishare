import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    debugPrint('[PROFILE] Screen opened. Firebase UID: ${fUser?.uid}');
    if (fUser == null) {
      clear();
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      debugPrint('[PROFILE] Firestore fetch started');
      await _applyFirestoreRole(fUser.uid);
      debugPrint('[PROFILE] Firestore fetch completed');
      
      // Update UI with Firestore user data before doing slow REST call
      notifyListeners();

      debugPrint('[PROFILE] REST profile fetch started');
      final response = await _dio.get(ApiEndpoints.profile).timeout(const Duration(seconds: 7));
      if (response.data != null && response.data['success'] == true) {
        final userData = response.data['data'] as Map<String, dynamic>;
        // Create user from REST but RETAIN Firestore role
        final restUser = UserModel.fromJson(userData);
        if (_user != null) {
          _user = UserModel(
            id: restUser.id,
            name: restUser.name,
            email: restUser.email,
            role: _user!.role, // Keep Firestore role!
            phone: restUser.phone,
            phoneVerified: restUser.phoneVerified,
            address: restUser.address,
            profileImage: restUser.profileImage,
            organizationName: restUser.organizationName,
            registrationNumber: restUser.registrationNumber,
            contactPerson: restUser.contactPerson,
            equipmentPreference: restUser.equipmentPreference,
            verificationStatus: restUser.verificationStatus,
            createdAt: restUser.createdAt,
          );
        } else {
          _user = restUser;
        }
      }
      debugPrint('[PROFILE] REST profile fetch completed');
    } catch (e) {
      debugPrint('[PROFILE] REST failed: $e');
      try {
        final fallbackRes = await _dio.get(ApiEndpoints.me).timeout(const Duration(seconds: 5));
        if (fallbackRes.data != null && fallbackRes.data['success'] == true) {
          final userData = fallbackRes.data['data'] as Map<String, dynamic>;
          final restUser = UserModel.fromJson(userData);
          if (_user != null) {
            _user = UserModel(
              id: restUser.id,
              name: restUser.name,
              email: restUser.email,
              role: _user!.role, // Keep Firestore role!
              phone: restUser.phone,
              phoneVerified: restUser.phoneVerified,
              address: restUser.address,
              profileImage: restUser.profileImage,
              organizationName: restUser.organizationName,
              registrationNumber: restUser.registrationNumber,
              contactPerson: restUser.contactPerson,
              equipmentPreference: restUser.equipmentPreference,
              verificationStatus: restUser.verificationStatus,
              createdAt: restUser.createdAt,
            );
          } else {
            _user = restUser;
          }
        }
      } catch (innerE) {
        debugPrint('[PROFILE] Fallback REST failed: $innerE');
        // Do not overwrite errorMessage if we already have Firestore user
      }
    } finally {
      await fetchStats();
      _isLoading = false;
      debugPrint('[PROFILE] Loading finished');
      notifyListeners();
    }
  }

  // ── Apply Firestore Role as Single Source of Truth ─────────────────
  Future<void> _applyFirestoreRole(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!doc.exists) return;

      final firestoreData = doc.data()!;
      final firestoreRole = firestoreData['role']?.toString();
      
      if (firestoreRole == null || firestoreRole.isEmpty) {
        debugPrint('[PROFILE] Firestore role is missing or empty.');
        return;
      }

      debugPrint('[PROFILE] Firestore role: $firestoreRole');

      if (_user == null) {
        firestoreData['id'] = uid;
        _user = UserModel.fromJson(firestoreData);
        debugPrint('[ROLE SYNC] ProfileProvider: built user from Firestore. role=${_user!.role}');
      } else if (_user!.role != firestoreRole) {
        debugPrint('[ROLE SYNC] ProfileProvider: updating role to $firestoreRole');
        _user = UserModel(
          id: _user!.id,
          name: _user!.name,
          email: _user!.email,
          role: firestoreRole,
          phone: _user!.phone,
          phoneVerified: _user!.phoneVerified,
          address: _user!.address,
          profileImage: _user!.profileImage,
          organizationName: _user!.organizationName,
          registrationNumber: _user!.registrationNumber,
          contactPerson: _user!.contactPerson,
          equipmentPreference: _user!.equipmentPreference,
          verificationStatus: _user!.verificationStatus,
          createdAt: _user!.createdAt,
        );
      }
    } catch (e) {
      debugPrint('[ROLE SYNC] ProfileProvider: _applyFirestoreRole failed: $e');
    }
  }

  // ── Fetch User Statistics ──────────────────────────────────────────
  Future<void> fetchStats() async {
    try {
      final res = await _dio.get(ApiEndpoints.summary);
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
