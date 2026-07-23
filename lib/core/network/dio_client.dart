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

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
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
          final token = await _storage.read(key: 'medishare_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Handle 401 globally
          if (error.response?.statusCode == 401) {
            _storage.delete(key: 'medishare_token');
            _storage.delete(key: 'medishare_user');
          }
          return handler.next(error);
        },
      ),
    );

    // ── Log Interceptor ───────────────────────────────────
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
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
      return AppStrings.networkError;
    }
    if (e.type == DioExceptionType.connectionError) {
      return AppStrings.networkError;
    }
    final data = e.response?.data;
    if (data is Map) {
      if (data.containsKey('message') && data['message'] != null && data['message'].toString().isNotEmpty) {
        return data['message'].toString();
      }
      if (data.containsKey('error') && data['error'] != null && data['error'].toString().isNotEmpty) {
        return data['error'].toString();
      }
      if (data.containsKey('errors') && data['errors'] is List && (data['errors'] as List).isNotEmpty) {
        final firstErr = (data['errors'] as List).first;
        if (firstErr is Map && firstErr.containsKey('message')) {
          return firstErr['message'].toString();
        }
        return firstErr.toString();
      }
    }
    return AppStrings.genericError;
  }

  static void debugLog(String message) {
    // Only log in debug mode
    assert(() {
      // ignore: avoid_print
      print('[DioClient] $message');
      return true;
    }());
  }
}
