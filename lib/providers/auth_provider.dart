import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../core/services/fcm_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Auth Provider — manages authentication state across the app.
/// Used with Provider + ChangeNotifier.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // ── State ─────────────────────────────────────────────
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  bool _isOtpSending = false;
  bool _isOtpVerifying = false;
  bool _isPasswordResetting = false;

  // ── Getters ───────────────────────────────────────────
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isOtpSending => _isOtpSending;
  bool get isOtpVerifying => _isOtpVerifying;
  bool get isPasswordResetting => _isPasswordResetting;

  // ── Init: Check existing JWT on app launch ────────────
  Future<void> checkAuthStatus() async {
    if (_status == AuthStatus.loading) return;
    _setStatus(AuthStatus.loading);
    try {
      final hasToken = await _authService.hasToken();
      if (!hasToken) {
        _setStatus(AuthStatus.unauthenticated);
        return;
      }
      
      // Attempt to load profile from backend / local secure storage
      final user = await _authService.getMe();
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (user != null && firebaseUser != null && user.id == firebaseUser.uid) {
        _user = user;
        _setStatus(AuthStatus.authenticated);
        debugPrint('[ROLE SYNC] AuthProvider.checkAuthStatus(): uid=${_user?.id} role=${_user?.role}');
        
        // Register FCM in background without awaiting
        FcmService().registerDeviceToken(_user!.id).ignore();
      } else {
        if (user != null) {
           debugPrint('[AUTH SYNC] Mismatch in checkAuthStatus. Backend user: ${user.id}, Firebase: ${firebaseUser?.uid}');
           await _authService.clearAuth();
        }
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (e) {
      debugPrint('[AuthProvider] checkAuthStatus error: $e');
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  // ── Login ─────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;
    try {
      final result = await _authService.login(email.trim(), password);
      final currentFirebaseUser = FirebaseAuth.instance.currentUser;
      if (currentFirebaseUser == null || currentFirebaseUser.uid != result.user.id) {
         debugPrint('[AUTH SYNC] Race condition detected in login(). Firebase UID changed. Aborting login.');
         await _authService.clearAuth();
         _setStatus(AuthStatus.unauthenticated);
         return false;
      }

      _user = result.user;
      debugPrint('[ROLE SYNC] AuthProvider.login(): uid=${_user?.id} role=${_user?.role}');
      debugPrint('CURRENT USER EMAIL = ${_user?.email}');
      debugPrint('CURRENT USER ROLE = ${_user?.role}');
      _setStatus(AuthStatus.authenticated);
      FcmService().registerDeviceToken(_user!.id);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFriendlyFirebaseAuthErrorMessage(e);
      debugPrint('[AuthProvider] login FirebaseAuthException: [${e.code}] $_errorMessage');
      _setStatus(AuthStatus.error);
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  static String _getFriendlyFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
        return 'Incorrect email or password. Please verify your credentials or register a new account. [invalid-credential]';
      case 'user-not-found':
        return 'No user found with this email. Please check your email or register. [user-not-found]';
      case 'wrong-password':
        return 'Incorrect password. Please try again. [wrong-password]';
      case 'invalid-email':
        return 'The email address is improperly formatted. [invalid-email]';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support. [user-disabled]';
      case 'email-already-in-use':
        return 'An account already exists with this email address. Please log in instead. [email-already-in-use]';
      case 'weak-password':
        return 'The password provided is too weak. Please use at least 6 characters. [weak-password]';
      case 'too-many-requests':
        return 'Too many unsuccessful attempts. Please wait a moment and try again. [too-many-requests]';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Console. [operation-not-allowed]';
      case 'network-request-failed':
        return 'Network error: Unable to reach Firebase. Please check your internet connection. [network-request-failed]';
      case 'app-not-authorized':
        return 'This app is not authorized to use Firebase Authentication. [app-not-authorized]';
      default:
        return '${e.message ?? "Authentication failed."} [${e.code}]';
    }
  }



  // ── Register ──────────────────────────────────────────
  Future<bool> register({
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
    _setStatus(AuthStatus.loading);
    _errorMessage = null;
    try {
      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
        address: address,
        organizationName: organizationName,
        registrationNumber: registrationNumber,
        contactPerson: contactPerson,
        equipmentPreference: equipmentPreference,
      );
      _user = result.user;
      if (result.otpError != null && result.otpError!.isNotEmpty) {
        _errorMessage = result.otpError;
      }
      _setStatus(AuthStatus.authenticated);
      FcmService().registerDeviceToken(_user!.id);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFriendlyFirebaseAuthErrorMessage(e);
      debugPrint('[AuthProvider] register FirebaseAuthException: [${e.code}] $_errorMessage');
      _setStatus(AuthStatus.error);
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // ── OTP ───────────────────────────────────────────────
  Future<bool> sendOtp(String phone) async {
    if (_isOtpSending) return false;
    _isOtpSending = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await _authService.sendOtp(phone);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isOtpSending = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    if (_isOtpVerifying) return false;
    _isOtpVerifying = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final success = await _authService.verifyOtp(phone, otp);
      if (success) {
        final cachedUser = await _authService.getCachedUser();
        if (cachedUser != null) {
          _user = cachedUser;
        }
        final hasToken = await _authService.hasToken();
        if (hasToken) {
          _setStatus(AuthStatus.authenticated);
        }
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isOtpVerifying = false;
      notifyListeners();
    }
  }

  Future<bool> resendOtp(String phone) async {
    if (_isOtpSending) return false;
    _isOtpSending = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await _authService.resendOtp(phone);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isOtpSending = false;
      notifyListeners();
    }
  }

  // ── Forgot Password Flow ──────────────────────────────
  Future<bool> sendForgotPasswordOtp(String target, String type) async {
    if (_isOtpSending) return false;
    _isOtpSending = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await _authService.sendForgotPasswordOtp(target, type);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isOtpSending = false;
      notifyListeners();
    }
  }

  Future<String?> verifyForgotPasswordOtp(
    String target,
    String type,
    String otp,
  ) async {
    if (_isOtpVerifying) return null;
    _isOtpVerifying = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await _authService.verifyForgotPasswordOtp(target, type, otp);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isOtpVerifying = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(
    String target,
    String type,
    String resetToken,
    String newPassword,
  ) async {
    if (_isPasswordResetting) return false;
    _isPasswordResetting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await _authService.resetPassword(
        target,
        type,
        resetToken,
        newPassword,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isPasswordResetting = false;
      notifyListeners();
    }
  }

  // ── Logout ────────────────────────────────────────────
  Future<void> logout() async {
    debugPrint('[LOGOUT] Provider cleanup started');
    _setStatus(AuthStatus.loading);
    try {
      await _authService.clearAuth();
    } catch (e) {
      debugPrint('[LOGOUT] Error in clearAuth: $e');
    }
    _user = null;
    _setStatus(AuthStatus.unauthenticated);
    debugPrint('[LOGOUT] Navigation to login ready');
  }

  // ── Clear Error ───────────────────────────────────────
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // ── Internal ──────────────────────────────────────────
  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
}
