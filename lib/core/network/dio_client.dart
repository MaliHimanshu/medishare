import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_strings.dart';
import 'api_endpoints.dart';

/// Dio client with:
/// - JWT auth interceptor (reads from secure storage)
/// - Error interceptor (maps Dio errors to human-readable messages)
/// - Request/Response logging in debug mode
class DioClient {
  DioClient._();

  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static Dio? _instance;

  /// Global callback for 401 unauthorized handling
  static void Function()? onUnauthorized;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // ── Auth Interceptor ──────────────────────────────────
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            String? token = await _storage.read(key: 'auth_token');
            token ??= await _storage.read(key: 'medishare_token');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {}
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 globally
          if (error.response?.statusCode == 401) {
            try {
              await _storage.delete(key: 'auth_token');
              await _storage.delete(key: 'medishare_token');
              await _storage.delete(key: 'medishare_user');
            } catch (_) {}
            onUnauthorized?.call();
          }
          return handler.next(error);
        },
      ),
    );

    // ── Log Interceptor ───────────────────────────────────
    dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        error: true,
        logPrint: (obj) => debugLog(obj.toString()),
      ),
    );

    return dio;
  }

  // ── Helper: Map DioException to readable message ───────
  static String handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Request timed out. Please check your connection and try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach the server. Please check your internet or verify backend is running.';
    }
    final data = e.response?.data;
    if (data is Map) {
      if (data.containsKey('message') &&
          data['message'] != null &&
          data['message'].toString().isNotEmpty) {
        return data['message'].toString();
      }
      if (data.containsKey('error') &&
          data['error'] != null &&
          data['error'].toString().isNotEmpty) {
        return data['error'].toString();
      }
      if (data.containsKey('errors') &&
          data['errors'] is List &&
          (data['errors'] as List).isNotEmpty) {
        final firstErr = (data['errors'] as List).first;
        if (firstErr is Map && firstErr.containsKey('message')) {
          return firstErr['message'].toString();
        }
        return firstErr.toString();
      }
    }
    if (e.response?.statusCode != null) {
      return 'Server returned error (${e.response!.statusCode}). Please try again.';
    }
    return AppStrings.genericError;
  }

  static void debugLog(String message) {
    // ignore: avoid_print
    print('[DioClient] $message');
  }
}
