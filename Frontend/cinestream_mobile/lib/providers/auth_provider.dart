import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
final AuthService _authService = AuthService.instance;

User? _user;
bool _isLoading = false;
String? _errorMessage;

User? get user => _user;
bool get isLoading => _isLoading;
String? get errorMessage => _errorMessage;

bool get isAuthenticated => _user != null;

Future<bool> login({
required String usernameOrEmail,
required String password,
}) async {
_setLoading(true);
_errorMessage = null;


try {
  _user = await _authService.login(
    usernameOrEmail: usernameOrEmail,
    password: password,
  );

  return true;
} catch (e) {
  _errorMessage = _cleanErrorMessage(e);
  _user = null;
  return false;
} finally {
  _setLoading(false);
}


}

Future<bool> register({
required String username,
required String email,
required String password,
}) async {
_setLoading(true);
_errorMessage = null;


try {
  await _authService.register(
    username: username,
    email: email,
    password: password,
  );

  // Đăng ký chỉ tạo tài khoản và gửi mã xác minh.
  // Chưa đăng nhập và chưa có User trong session.
  _user = null;

  return true;
} catch (e) {
  _errorMessage = _cleanErrorMessage(e);
  return false;
} finally {
  _setLoading(false);
}


}

Future<bool> verifyEmail({
required String email,
required String code,
}) async {
_setLoading(true);
_errorMessage = null;


try {
  await _authService.verifyEmail(
    email: email,
    code: code,
  );

  return true;
} catch (e) {
  _errorMessage = _cleanErrorMessage(e);
  return false;
} finally {
  _setLoading(false);
}


}

Future<bool> resendVerification({
required String email,
}) async {
_setLoading(true);
_errorMessage = null;


try {
  await _authService.resendVerification(
    email: email,
  );

  return true;
} catch (e) {
  _errorMessage = _cleanErrorMessage(e);
  return false;
} finally {
  _setLoading(false);
}


}

Future<bool> forgotPassword({
required String email,
}) async {
_setLoading(true);
_errorMessage = null;


try {
  await _authService.forgotPassword(
    email: email,
  );

  return true;
} catch (e) {
  _errorMessage = _cleanErrorMessage(e);
  return false;
} finally {
  _setLoading(false);
}


}

Future<bool> resetPassword({
required String email,
required String code,
required String newPassword,
}) async {
_setLoading(true);
_errorMessage = null;


try {
  await _authService.resetPassword(
    email: email,
    code: code,
    newPassword: newPassword,
  );

  return true;
} catch (e) {
  _errorMessage = _cleanErrorMessage(e);
  return false;
} finally {
  _setLoading(false);
}


}

Future<void> checkLoginStatus() async {
final isLoggedIn = await _authService.isLoggedIn();


if (!isLoggedIn) {
  _user = null;
  _errorMessage = null;
  notifyListeners();
  return;
}

try {
  _user = await _authService.getMe();
  _errorMessage = null;
} catch (_) {
  _user = null;
}

notifyListeners();


}

Future<void> logout() async {
await _authService.logout();


_user = null;
_errorMessage = null;

notifyListeners();


}

void clearError() {
_errorMessage = null;
notifyListeners();
}

void _setLoading(bool value) {
_isLoading = value;
notifyListeners();
}

String _cleanErrorMessage(Object error) {
return error
.toString()
.replaceFirst('Exception: ', '')
.trim();
}
}
