import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

/// Auth Service — handles all authentication API calls
/// and JWT storage via flutter_secure_storage.
class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'medishare_user';

  final Dio _dio = DioClient.instance;

  Future<AuthResponseModel> login(String email, String password) async {
    try {
      final sanitizedDomain = email.contains('@') ? '@${email.split('@').last}' : '(invalid)';
      debugPrint('[AuthService] Attempting signInWithEmailAndPassword (domain: $sanitizedDomain)...');
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('[AuthService] signInWithEmailAndPassword succeeded for uid: ${credential.user?.uid}');

      UserModel user;
      try {
        // Try Firestore with a generous timeout (Render cold starts can take 5-7s)
        DocumentSnapshot<Map<String, dynamic>>? doc;
        try {
          doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(credential.user!.uid)
              .get()
              .timeout(const Duration(seconds: 10));
        } catch (timeoutErr) {
          debugPrint('[AuthService][ROLE SYNC] First Firestore read timed out, retrying without timeout: $timeoutErr');
          // Retry once without timeout — role MUST be correct
          doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(credential.user!.uid)
              .get();
        }
            
        if (doc.exists) {
          final data = doc.data()!;
          data['id'] = credential.user!.uid;
          user = UserModel.fromJson(data);
          debugPrint('[ROLE SYNC] login() Firestore role: ${user.role} for uid: ${credential.user!.uid}');
        } else {
          // Document truly doesn't exist — create a minimal placeholder.
          // Do NOT default to DONOR; role will be resolved on next fetchProfile().
          debugPrint('[ROLE SYNC] login() Firestore doc missing for uid: ${credential.user!.uid}');
          user = UserModel(
            id: credential.user!.uid,
            name: credential.user!.displayName ?? 'User',
            email: email,
            role: 'UNKNOWN',
            createdAt: DateTime.now(),
          );
        }
      } catch (e) {
        debugPrint('[AuthService][ROLE SYNC] Profile fetch failed after retry: $e');
        // Still do NOT default to DONOR — use UNKNOWN so the UI knows to resolve
        user = UserModel(
          id: credential.user!.uid,
          name: credential.user!.displayName ?? 'User',
          email: email,
          role: 'UNKNOWN',
          createdAt: DateTime.now(),
        );
      }

      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
      return AuthResponseModel(
        success: true,
        message: 'Logged in successfully',
        user: user,
        token: '',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] FirebaseAuthException: code=${e.code}, message=${e.message}');
      throw Exception(e.message ?? 'Authentication failed.');
    } catch (e) {
      debugPrint('[AuthService] Unexpected error during login: $e');
      throw Exception(e.toString());
    }
  }

  // ── Register ──────────────────────────────────────────
  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? address,
    String? organizationName,
    String? registrationNumber,
    String? contactPerson,
    String? equipmentPreference,
  }) async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user!.updateDisplayName(name);

      final user = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
        role: role,
        phone: phone,
        address: address,
        organizationName: organizationName,
        registrationNumber: registrationNumber,
        contactPerson: contactPerson,
        equipmentPreference: equipmentPreference,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('users').doc(user.id).set(user.toJson());
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

      return AuthResponseModel(
        success: true,
        message: 'Registered successfully',
        user: user,
        token: '',
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Registration failed.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ── OTP ───────────────────────────────────────────────
  Future<bool> sendOtp(String phone) async {
    try {
      await _dio.post(ApiEndpoints.sendOtp, data: {'phone': phone});
      return true;
    } on DioException catch (e) {
      throw Exception(DioClient.handleError(e));
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    try {
      final success = await _dio.post(ApiEndpoints.verifyOtp, data: {'phone': phone, 'otp': otp});
      // OTP verification for phone typically doesn't login the user into Firebase.
      return success.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(DioClient.handleError(e));
    }
  }

  Future<bool> resendOtp(String phone) async {
    try {
      await _dio.post(ApiEndpoints.resendOtp, data: {'phone': phone});
      return true;
    } on DioException catch (e) {
      throw Exception(DioClient.handleError(e));
    }
  }

  // ── Forgot Password Flow ──────────────────────────────
  Future<bool> sendForgotPasswordOtp(String target, String type) async {
    try {
      if (type == 'email') {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: target);
        return true;
      }
      return false; // Phone reset not natively supported by Firebase Auth in this simplified manner without custom logic
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Failed to send password reset email.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<String> verifyForgotPasswordOtp(
    String target,
    String type,
    String otp,
  ) async {
    // With Firebase Auth native password reset, verification is handled via email link.
    // This is no longer applicable for email resets in the app UI.
    throw Exception('Password reset verification is now handled via email link.');
  }

  Future<bool> resetPassword(
    String target,
    String type,
    String resetToken,
    String newPassword,
  ) async {
    // Handled via Firebase native email link.
    throw Exception('Password reset is now handled via email link.');
  }

  Future<UserModel?> getMe() async {
    try {
      final fUser = FirebaseAuth.instance.currentUser;
      if (fUser == null) return null;

      // Try with generous timeout; retry without timeout if it fails
      DocumentSnapshot<Map<String, dynamic>>? doc;
      try {
        doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(fUser.uid)
            .get()
            .timeout(const Duration(seconds: 10));
      } catch (timeoutErr) {
        debugPrint('[AuthService][ROLE SYNC] getMe() timed out, retrying: $timeoutErr');
        doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(fUser.uid)
            .get();
      }

      if (doc != null && doc!.exists) {
        final data = doc.data()!;
        data['id'] = fUser.uid;
        final user = UserModel.fromJson(data);
        debugPrint('[ROLE SYNC] getMe() Firestore role: ${user.role} uid: ${fUser.uid}');
        // Always update cache with the fresh Firestore role
        await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
        return user;
      }
      debugPrint('[ROLE SYNC] getMe() Firestore doc missing for uid: ${fUser.uid}');
      return null;
    } catch (e) {
      debugPrint('[ROLE SYNC] getMe() Firestore read failed: $e — falling back to cache');
      return await getCachedUser();
    }
  }

  // ── Storage Helpers ───────────────────────────────────
  Future<UserModel?> getCachedUser() async {
    try {
      final raw = await _storage.read(key: _userKey);
      if (raw == null) return null;
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAuth() async {
    try {
      await FirebaseAuth.instance.signOut();
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: 'medishare_token');
      await _storage.delete(key: _userKey);
    } catch (_) {}
  }

  Future<bool> hasToken() async {
    // Verify Firebase has an active session
    return FirebaseAuth.instance.currentUser != null;
  }
}
