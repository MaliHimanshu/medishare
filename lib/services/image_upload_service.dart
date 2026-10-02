import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/network/api_endpoints.dart';

/// Service dedicated to image picking and upload to the MediShare backend
/// (POST /api/upload → Cloudinary), authenticated via Firebase ID token.
class ImageUploadService {
  ImageUploadService._();
  static final ImageUploadService instance = ImageUploadService._();

  final ImagePicker _picker = ImagePicker();

  // ── Permission ────────────────────────────────────────────────────────────

  Future<bool> checkPermission(ImageSource source) async {
    if (Platform.isAndroid) {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        return status.isGranted;
      }
      return true; // Android 13+ Photo Picker handles gallery natively
    } else if (Platform.isIOS) {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        return status.isGranted;
      } else {
        final status = await Permission.photos.request();
        return status.isGranted || status.isLimited;
      }
    }
    return true;
  }

  // ── Pick ─────────────────────────────────────────────────────────────────

  Future<File?> pickImage(ImageSource source) async {
    try {
      final hasPerm = await checkPermission(source);
      if (!hasPerm) return null;

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      debugPrint('[ImageUploadService] pickImage error: $e');
      rethrow;
    }
  }

  // ── Upload ────────────────────────────────────────────────────────────────

  /// Upload [file] to POST /api/upload.
  ///
  /// Strategy:
  ///  1. Force-refresh the Firebase ID token (getIdToken(true)).
  ///  2. POST multipart/form-data to the backend.
  ///  3. On 401: force-refresh token ONCE more and retry.
  ///  4. Never sign the user out.
  Future<String> uploadImage(
    File file, {
    void Function(int sent, int total)? onProgress,
  }) async {
    // Attempt 1 with force-refreshed token
    final token1 = await _getFreshToken();
    try {
      return await _doUpload(file, token1, onProgress);
    } on _UploadUnauthorizedException catch (e) {
      // 401 received — log it, refresh token once more, retry
      debugPrint('[ImageUploadService] 401 on attempt 1. Backend code=${e.code} msg="${e.serverMessage}"');
      debugPrint('[ImageUploadService] Force-refreshing token and retrying...');

      final token2 = await _getFreshToken(forceRefresh: true);
      try {
        return await _doUpload(file, token2, onProgress);
      } on _UploadUnauthorizedException catch (e2) {
        // Still 401 after refresh — expose the exact backend error to the user
        debugPrint('[ImageUploadService] 401 on attempt 2. Backend code=${e2.code} msg="${e2.serverMessage}"');
        throw Exception(
          'Upload authentication failed (${e2.code}): ${e2.serverMessage}. '
          'Please check backend Firebase Admin configuration.',
        );
      }
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<String> _getFreshToken({bool forceRefresh = true}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('You are not signed in. Please log in and try again.');
    }
    try {
      final token = await user.getIdToken(forceRefresh);
      if (token == null || token.isEmpty) throw Exception('empty token');
      debugPrint('[ImageUploadService] token obtained (uid=${user.uid})');
      return token;
    } catch (e) {
      debugPrint('[ImageUploadService] getIdToken error: $e');
      throw Exception('Could not refresh your session. Please log in again.');
    }
  }

  Future<String> _doUpload(
    File file,
    String idToken,
    void Function(int sent, int total)? onProgress,
  ) async {
    final fileName = file.path.split('/').last.split('\\').last;
    debugPrint('[ImageUploadService] POST /api/upload  file=$fileName  baseUrl=${ApiEndpoints.baseUrl}');

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName.isNotEmpty ? fileName : 'upload.jpg',
      ),
    });

    // Dedicated one-shot Dio instance — avoids stale headers from shared DioClient
    final uploadDio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Accept': 'application/json',
        },
      ),
    );

    try {
      final response = await uploadDio.post(
        ApiEndpoints.upload,
        data: formData,
        onSendProgress: onProgress,
      );

      debugPrint('[ImageUploadService] HTTP ${response.statusCode}  data=${response.data}');

      final data = response.data;
      if (data is Map) {
        final url = data['url']?.toString() ??
            (data['data'] is Map ? data['data']['url']?.toString() : null);
        if (url != null && url.isNotEmpty) {
          debugPrint('[ImageUploadService] Cloudinary URL: $url');
          return url;
        }
      }
      throw Exception('Backend returned an unexpected response format.');
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final serverData = e.response?.data;
      final serverMsg = _extractServerMessage(serverData);
      final serverCode = _extractServerCode(serverData);

      debugPrint('[ImageUploadService] DioException  type=${e.type}  HTTP=$statusCode  code=$serverCode  msg="$serverMsg"');

      if (statusCode == 401) {
        // Throw a typed exception so the caller can retry
        throw _UploadUnauthorizedException(
          code: serverCode ?? 'unknown',
          serverMessage: serverMsg ?? 'Unauthorized',
        );
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Upload timed out. Check your connection and try again.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot reach the server. Check your internet connection.');
      }
      if (statusCode == 400) {
        throw Exception(serverMsg ?? 'Invalid image. Please select a different file.');
      }
      if (statusCode == 413) {
        throw Exception('Image is too large. Please select a smaller file.');
      }
      throw Exception(serverMsg ?? 'Image upload failed. Please try again.');
    }
  }

  String? _extractServerMessage(dynamic data) {
    if (data is Map) {
      return data['message']?.toString() ?? data['error']?.toString();
    }
    return null;
  }

  String? _extractServerCode(dynamic data) {
    if (data is Map) {
      return data['code']?.toString();
    }
    return null;
  }
}

/// Internal exception used to trigger the token-refresh retry on 401.
class _UploadUnauthorizedException implements Exception {
  final String code;
  final String serverMessage;
  const _UploadUnauthorizedException({required this.code, required this.serverMessage});
}
