import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/storage_service.dart';
import '../models/user.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final Dio _dio = ApiClient.instance.dio;

  Future<User> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'usernameOrEmail': usernameOrEmail,
          'password': password,
        },
      );

      final data = response.data;

      final token = data['data']?['token'] ?? data['token'];

      if (token == null || token.toString().isEmpty) {
        throw Exception('Đăng nhập thành công nhưng không nhận được JWT token.');
      }

      await StorageService.saveToken(token.toString());

      final userJson = data['data']?['user'] ?? data['user'];

      if (userJson == null) {
        throw Exception('Không nhận được thông tin người dùng.');
      }

      final user = User.fromJson(
        Map<String, dynamic>.from(userJson),
      );

      await StorageService.saveUserId(user.id);

      return user;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            'Đăng nhập thất bại. Vui lòng kiểm tra kết nối.',
      );
    }
  }

  Future<User> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      final data = response.data;

      final userJson = data['data']?['user'] ?? data['user'] ?? data['data'];

      if (userJson == null || userJson is! Map) {
        throw Exception('Đăng ký thành công nhưng dữ liệu người dùng không hợp lệ.');
      }

      return User.fromJson(
        Map<String, dynamic>.from(userJson),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            'Đăng ký thất bại. Vui lòng thử lại.',
      );
    }
  }

  Future<void> logout() async {
    await StorageService.clearSession();
  }

  Future<bool> isLoggedIn() async {
    return StorageService.isLoggedIn();
  }

  Future<String?> getToken() async {
    return StorageService.getToken();
  }
}