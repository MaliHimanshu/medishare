import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Auth Provider — manages authentication state across the app.
/// Used with Provider + ChangeNotifier.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // ── State ─────────────────────────────────────────────
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String?    _errorMessage;

  // ── Getters ───────────────────────────────────────────
  AuthStatus get status         => _status;
  UserModel? get user           => _user;
  String?    get errorMessage   => _errorMessage;
  bool       get isAuthenticated => _status == AuthStatus.authenticated;
  bool       get isLoading       => _status == AuthStatus.loading;

  // ── Init: Check existing JWT on app launch ────────────
  Future<void> checkAuthStatus() async {
    _setStatus(AuthStatus.loading);
    try {
      final hasToken = await _authService.hasToken();
      if (!hasToken) {
        _setStatus(AuthStatus.unauthenticated);
        return;
      }
      // Validate token by fetching user profile
      final user = await _authService.getMe();
      if (user != null) {
        _user = user;
        _setStatus(AuthStatus.authenticated);
      } else {
        await _authService.clearAuth();
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (_) {
      await _authService.clearAuth();
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  // ── Login ─────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;
    try {
      final result = await _authService.login(email, password);
      _user = result.user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setStatus(AuthStatus.error);
      return false;
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
  }) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;
    try {
      final result = await _authService.register(
        name:     name,
        email:    email,
        password: password,
        role:     role,
        phone:    phone,
        address:  address,
      );
      _user = result.user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────
  Future<void> logout() async {
    _setStatus(AuthStatus.loading);
    await _authService.clearAuth();
    _user = null;
    _setStatus(AuthStatus.unauthenticated);
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
