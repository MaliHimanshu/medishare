import 'user_model.dart';

/// Wraps the backend auth response: { success, message, data: user, token }
class AuthResponseModel {
  final bool success;
  final String message;
  final UserModel user;
  final String token;

  const AuthResponseModel({
    required this.success,
    required this.message,
    required this.user,
    required this.token,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      user:    UserModel.fromJson(json['data'] as Map<String, dynamic>),
      token:   json['token']?.toString() ?? '',
    );
  }
}
