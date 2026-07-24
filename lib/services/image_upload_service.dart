import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/network/api_endpoints.dart';
import '../core/network/dio_client.dart';

/// Service dedicated to image picking and backend multipart/form-data upload.
class ImageUploadService {
  ImageUploadService._();
  static final ImageUploadService instance = ImageUploadService._();

  final ImagePicker _picker = ImagePicker();

  /// Check permission for Camera or Photos
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

  /// Pick an image file from specified source (camera or gallery)
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
      DioClient.debugLog("Image pick error: $e");
      rethrow;
    }
  }

  /// Upload image file to backend Cloudinary endpoint (/api/upload)
  /// using multipart/form-data and returning secure Cloudinary image URL.
  Future<String> uploadImage(File file, {void Function(int sent, int total)? onProgress}) async {
    try {
      final fileName = file.path.split('/').last.split('\\').last;
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName.isNotEmpty ? fileName : 'upload.jpg',
        ),
      });

      final response = await DioClient.instance.post(
        ApiEndpoints.upload,
        data: formData,
        onSendProgress: onProgress,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data != null && data is Map) {
          if (data['url'] != null && data['url'].toString().isNotEmpty) {
            return data['url'].toString();
          }
          if (data['data'] != null && data['data'] is Map && data['data']['url'] != null) {
            return data['data']['url'].toString();
          }
        }
      }

      throw Exception(response.data?['message'] ?? 'Failed to process image upload.');
    } on DioException catch (e) {
      final msg = DioClient.handleError(e);
      DioClient.debugLog("Image upload DioException: $msg");
      throw Exception(msg);
    } catch (e) {
      DioClient.debugLog("Image upload unexpected error: $e");
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
