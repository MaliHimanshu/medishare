import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

/// Auth Service — handles all authentication API calls
/// and JWT storage via flutter_secure_storage.
class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'medishare_token';
  static const String _userKey  = 'medishare_user';

  final Dio _dio = DioClient.instance;

  // ── Login ─────────────────────────────────────────────
  /// POST /api/auth/login
  Future<AuthResponseModel> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final authResponse = AuthResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      await _persistAuth(authResponse.token, authResponse.user);
      return authResponse;
    } on DioException catch (e) {
      throw Exception(DioClient.handleError(e));
    }
  }

  // ── Register ──────────────────────────────────────────
  /// POST /api/auth/register
  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? address,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name':     name,
        'email':    email,
        'password': password,
        'role':     role,
        if (phone != null && phone.isNotEmpty)   'phone':   phone,
        if (address != null && address.isNotEmpty) 'address': address,
      };

      final response = await _dio.post(
        ApiEndpoints.register,
        data: payload,
      );
      final authResponse = AuthResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      await _persistAuth(authResponse.token, authResponse.user);
      return authResponse;
    } on DioException catch (e) {
      throw Exception(DioClient.handleError(e));
    }
  }

  // ── Get Me ────────────────────────────────────────────
  /// GET /api/auth/me (requires token in header)
  Future<UserModel?> getMe() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);
      final data = response.data as Map<String, dynamic>;
      return UserModel.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  // ── Storage Helpers ───────────────────────────────────
  Future<void> _persistAuth(String token, UserModel user) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey,  value: jsonEncode(user.toJson()));
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<UserModel?> getCachedUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAuth() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}