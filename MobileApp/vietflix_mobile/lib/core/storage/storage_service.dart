import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();

  static const String _tokenKey = 'access_token';
  static const String _userIdKey = 'user_id';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}