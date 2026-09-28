import 'user_model.dart';

/// Wraps the backend auth response: { success, message, data: user, token }
class AuthResponseModel {
  final bool success;
  final String message;
  final UserModel user;
  final String token;
  final bool? otpSent;
  final String? otpError;

  const AuthResponseModel({
    required this.success,
    required this.message,
    required this.user,
    required this.token,
    this.otpSent,
    this.otpError,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      success:  json['success'] as bool? ?? false,
      message:  json['message']?.toString() ?? '',
      user:     UserModel.fromJson((json['user'] ?? json['data']) as Map<String, dynamic>),
      token:    json['token']?.toString() ?? '',
      otpSent:  json['otpSent'] as bool?,
      otpError: json['otpError']?.toString(),
    );
  }
}
