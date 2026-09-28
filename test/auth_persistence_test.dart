import 'package:flutter_test/flutter_test.dart';
import 'package:medishare/models/auth_response_model.dart';
import 'package:medishare/models/user_model.dart';

void main() {
  group('Auth JWT and Model Persistence Unit Tests', () {
    test('AuthResponseModel correctly parses backend verifyOtp response with user and token', () {
      final jsonResponse = {
        'success': true,
        'message': 'Phone number verified successfully',
        'token': 'mock.jwt.token',
        'user': {
          'id': 'usr-123',
          'name': 'Test User',
          'email': 'test@example.com',
          'role': 'DONOR',
          'phone': '+918000917657',
          'phoneVerified': true,
        },
      };

      final authResponse = AuthResponseModel.fromJson(jsonResponse);

      expect(authResponse.token, equals('mock.jwt.token'));
      expect(authResponse.user.id, equals('usr-123'));
      expect(authResponse.user.name, equals('Test User'));
      expect(authResponse.user.role, equals('DONOR'));
      expect(authResponse.user.phoneVerified, isTrue);
    });

    test('AuthResponseModel correctly parses backend response with data key fallback', () {
      final jsonResponse = {
        'success': true,
        'message': 'Login successful',
        'token': 'mock.jwt.token.data',
        'data': {
          'id': 'usr-456',
          'name': 'Hospital Admin',
          'email': 'hospital@example.com',
          'role': 'HOSPITAL',
          'phone': '+919876543210',
          'phoneVerified': true,
        },
      };

      final authResponse = AuthResponseModel.fromJson(jsonResponse);

      expect(authResponse.token, equals('mock.jwt.token.data'));
      expect(authResponse.user.role, equals('HOSPITAL'));
      expect(authResponse.user.email, equals('hospital@example.com'));
    });

    test('UserModel correctly handles all 5 roles and phoneVerified flag', () {
      final roles = ['DONOR', 'NGO', 'HOSPITAL', 'RECIPIENT', 'ADMIN'];

      for (final role in roles) {
        final user = UserModel.fromJson({
          'id': 'user-$role',
          'name': '$role User',
          'email': '$role@test.com',
          'role': role,
          'phoneVerified': true,
        });

        expect(user.role.toUpperCase(), equals(role));
        expect(user.phoneVerified, isTrue);
      }
    });
  });
}
