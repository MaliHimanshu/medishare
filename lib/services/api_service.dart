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
        email: email.trim(),
        password: password,
      );
      debugPrint('[AuthService] signInWithEmailAndPassword succeeded for uid: ${credential.user?.uid}');

      final token = await credential.user!.getIdToken();
      if (token != null) {
        await _storage.write(key: _tokenKey, value: token);
      }

      UserModel? user;
      try {
        final response = await _dio.get(ApiEndpoints.me);
        if (response.data != null && response.data['success'] == true) {
          user = UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
          debugPrint('[ROLE SYNC] login() backend PostgreSQL role: ${user.role} for email: ${user.email}');
          debugPrint('AUTH SERVICE ROLE = ${user.role}');
          debugPrint('LOGIN EMAIL = ${user.email}');
          debugPrint('LOGIN ROLE = ${user.role}');
        }
      } catch (backendErr) {
        debugPrint('[AuthService] login() backend fetch failed: $backendErr');
      }

      // If backend API call was unreachable, fallback to cached user
      user ??= await getCachedUser();

      // SECURITY FIX: Never allow a previous cached user to leak into a new login session
      if (user != null && credential.user != null && user.id != credential.user!.uid) {
        debugPrint('[AuthService] SECURITY ALERT: Cached user UID (${user.id}) does not match Firebase UID (${credential.user!.uid}). Discarding cache.');
        user = null;
      }

      if (user == null && credential.user != null) {
        user = UserModel(
          id: credential.user!.uid,
          name: credential.user!.displayName ?? 'User',
          email: email.trim(),
          role: 'UNKNOWN',
          createdAt: DateTime.now(),
        );
      }

      if (user != null) {
        await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
        
        // Ensure Firestore role is synchronized with PostgreSQL source of truth
        // Crucial Fix: Use exact Firebase UID, not the PostgreSQL user.id, to ensure firestore.rules (request.auth.uid) matches
        try {
          final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
          if (firebaseUid != null) {
            debugPrint('[DIAGNOSTICS] ROLE SYNC START');
            debugPrint('[DIAGNOSTICS] Firebase UID: $firebaseUid');
            debugPrint('[DIAGNOSTICS] Backend role: ${user.role}');
            
            await FirebaseFirestore.instance.collection('users').doc(firebaseUid).set(
              {'role': user.role, 'name': user.name, 'email': user.email},
              SetOptions(merge: true),
            );
            debugPrint('[DIAGNOSTICS] ROLE SYNC SUCCESS');
          }
        } catch (syncErr) {
          final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
          debugPrint('[DIAGNOSTICS] ROLE SYNC FAILED');
          debugPrint('[DIAGNOSTICS] Firebase UID: $firebaseUid');
          if (syncErr is FirebaseException) {
            debugPrint('[DIAGNOSTICS] Error code: ${syncErr.code}');
            debugPrint('[DIAGNOSTICS] Error message: ${syncErr.message}');
          } else {
            debugPrint('[DIAGNOSTICS] Error message: $syncErr');
          }
        }
      }

      return AuthResponseModel(
        success: true,
        message: 'Logged in successfully',
        user: user!,
        token: token ?? '',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] FirebaseAuthException: code=${e.code}, message=${e.message}');
      rethrow;
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
        email: email.trim(),
        password: password,
      );

      await credential.user!.updateDisplayName(name);

      final user = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email.trim(),
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
      debugPrint('[AuthService] FirebaseAuthException during register: code=${e.code}, message=${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[AuthService] Unexpected error during register: $e');
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
      if (fUser == null) return await getCachedUser();

      final response = await _dio.get(ApiEndpoints.me);
      if (response.data != null && response.data['success'] == true) {
        final userData = response.data['data'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);
        debugPrint('[ROLE SYNC] getMe() backend PostgreSQL role: ${user.role} for email: ${user.email}');
        debugPrint('AUTH SERVICE ROLE = ${user.role}');
        await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
        return user;
      }
    } on DioException catch (e) {
      debugPrint('[AuthService] getMe() Dio error: $e');
    } catch (e) {
      debugPrint('[AuthService] getMe() error: $e');
    }
    
    final cached = await getCachedUser();
    final fUser = FirebaseAuth.instance.currentUser;
    if (cached != null && fUser != null && cached.id != fUser.uid) {
      debugPrint('[AuthService] SECURITY ALERT: Cached user UID (${cached.id}) does not match Firebase UID (${fUser.uid}). Discarding cache.');
      return null;
    }
    return cached;
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
      debugPrint('[LOGOUT] Firebase signOut started');
      await FirebaseAuth.instance.signOut().timeout(const Duration(seconds: 2));
      debugPrint('[LOGOUT] Firebase signOut completed');
    } catch (e) {
      debugPrint('[LOGOUT] Firebase signOut error/timeout: $e');
    }
    try {
      debugPrint('[LOGOUT] SecureStorage cleanup started');
      await _storage.delete(key: _tokenKey).timeout(const Duration(seconds: 1));
      await _storage.delete(key: 'medishare_token').timeout(const Duration(seconds: 1));
      await _storage.delete(key: _userKey).timeout(const Duration(seconds: 1));
      debugPrint('[LOGOUT] SecureStorage cleanup completed');
    } catch (e) {
      debugPrint('[LOGOUT] SecureStorage cleanup error/timeout: $e');
    }
  }

  Future<bool> hasToken() async {
    // Verify Firebase has an active session
    return FirebaseAuth.instance.currentUser != null;
  }
}
