import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService =
      AuthService.instance;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // ============================================================
  // GETTERS
  // ============================================================

  User? get user => _user;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get isAuthenticated =>
      _user != null;

  // ============================================================
  // LOGIN
  // ============================================================

  Future<bool> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.login(
        usernameOrEmail:
            usernameOrEmail,
        password: password,
      );

      return true;
    } catch (e) {
      _errorMessage =
          _cleanErrorMessage(e);
      _user = null;

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(
        username: username,
        email: email,
        password: password,
      );

      // Đăng ký chưa đăng nhập.
      _user = null;

      return true;
    } catch (e) {
      _errorMessage =
          _cleanErrorMessage(e);

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // VERIFY EMAIL
  // ============================================================

  Future<bool> verifyEmail({
    required String email,
    required String code,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.verifyEmail(
        email: email,
        code: code,
      );

      return true;
    } catch (e) {
      _errorMessage =
          _cleanErrorMessage(e);

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // RESEND VERIFICATION
  // ============================================================

  Future<bool> resendVerification({
    required String email,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resendVerification(
        email: email,
      );

      return true;
    } catch (e) {
      _errorMessage =
          _cleanErrorMessage(e);

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<bool> forgotPassword({
    required String email,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.forgotPassword(
        email: email,
      );

      return true;
    } catch (e) {
      _errorMessage =
          _cleanErrorMessage(e);

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );

      return true;
    } catch (e) {
      _errorMessage =
          _cleanErrorMessage(e);

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // CHECK LOGIN STATUS
  // ============================================================

  Future<void> checkLoginStatus() async {
    final isLoggedIn =
        await _authService.isLoggedIn();

    if (!isLoggedIn) {
      _user = null;
      _errorMessage = null;
      notifyListeners();

      return;
    }

    try {
      _user =
          await _authService.getMe();
      _errorMessage = null;
    } catch (e) {
      _user = null;

      // Không hiển thị lỗi khi app chỉ đang
      // kiểm tra session lúc khởi động.
      _errorMessage = null;
    }

    notifyListeners();
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  Future<bool> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser =
          await _authService.updateProfile(
        displayName: displayName,
        avatarUrl: avatarUrl,
        bio: bio,
      );

      _user = updatedUser;
      _errorMessage = null;

      return true;
    } catch (e) {
      _errorMessage =
          _cleanErrorMessage(e);

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // SET USER FROM EXTERNAL SOURCE
  // ============================================================

  void setUserFromExternalSource(
    User user,
  ) {
    _user = user;
    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.changePassword(
        currentPassword:
            currentPassword,
        newPassword:
            newPassword,
        confirmNewPassword:
            confirmNewPassword,
      );

      _errorMessage = null;

      return true;
    } catch (e) {
      _errorMessage =
          _cleanErrorMessage(e);

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    try {
      await _authService.logout();
    } finally {
      _user = null;
      _errorMessage = null;

      notifyListeners();
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  String _cleanErrorMessage(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }
}