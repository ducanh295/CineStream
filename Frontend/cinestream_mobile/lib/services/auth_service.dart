import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/storage_service.dart';
import '../models/user.dart';

class AuthService {
  AuthService._();

  static final AuthService instance =
      AuthService._();

  final Dio _dio =
      ApiClient.instance.dio;

  // ================================================================
  // LOGIN
  // ================================================================

  Future<User> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final response =
          await _dio.post(
        ApiConstants.login,
        data: {
          'usernameOrEmail':
              usernameOrEmail.trim(),
          'password':
              password,
        },
      );

      final body =
          _asMap(response.data);

      _ensureSuccess(
        body,
        'Đăng nhập thất bại.',
      );

      final data =
          _asMap(body['data']);

      final token =
          data['token']?.toString();

      if (token == null ||
          token.isEmpty) {
        throw Exception(
          'Đăng nhập thành công nhưng không nhận được JWT token.',
        );
      }

      final userJson =
          data['user'];

      if (userJson is! Map) {
        throw Exception(
          'Không nhận được thông tin người dùng.',
        );
      }

      final user =
          User.fromJson(
        Map<String, dynamic>.from(
          userJson,
        ),
      );

      await StorageService.saveToken(
        token,
      );

      await StorageService.saveUserId(
        user.id,
      );

      return user;
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e,
          'Đăng nhập thất bại. Vui lòng kiểm tra kết nối.',
        ),
      );
    }
  }

  // ================================================================
  // REGISTER
  // ================================================================

  Future<String> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response =
          await _dio.post(
        ApiConstants.register,
        data: {
          'username':
              username.trim(),
          'email':
              email.trim(),
          'password':
              password,
        },
      );

      final body =
          _asMap(response.data);

      _ensureSuccess(
        body,
        'Đăng ký thất bại.',
      );

      return body['message']
              ?.toString() ??
          'Đăng ký thành công. Vui lòng kiểm tra email để xác minh tài khoản.';
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e,
          'Đăng ký thất bại. Vui lòng thử lại.',
        ),
      );
    }
  }

  // ================================================================
  // VERIFY EMAIL
  // ================================================================

  Future<String> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response =
          await _dio.post(
        ApiConstants.verifyEmail,
        data: {
          'email':
              email.trim(),
          'code':
              code.trim(),
        },
      );

      final body =
          _asMap(response.data);

      _ensureSuccess(
        body,
        'Xác minh email thất bại.',
      );

      return body['message']
              ?.toString() ??
          'Xác minh email thành công.';
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e,
          'Xác minh email thất bại.',
        ),
      );
    }
  }

  // ================================================================
  // RESEND VERIFICATION
  // ================================================================

  Future<String> resendVerification({
    required String email,
  }) async {
    try {
      final response =
          await _dio.post(
        ApiConstants.resendVerification,
        data: {
          'email':
              email.trim(),
        },
      );

      final body =
          _asMap(response.data);

      _ensureSuccess(
        body,
        'Không thể gửi lại mã xác minh.',
      );

      return body['message']
              ?.toString() ??
          'Mã xác minh mới đã được gửi.';
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e,
          'Không thể gửi lại mã xác minh.',
        ),
      );
    }
  }

  // ================================================================
  // FORGOT PASSWORD
  // ================================================================

  Future<String> forgotPassword({
    required String email,
  }) async {
    try {
      final response =
          await _dio.post(
        ApiConstants.forgotPassword,
        data: {
          'email':
              email.trim(),
        },
      );

      final body =
          _asMap(response.data);

      _ensureSuccess(
        body,
        'Không thể yêu cầu đặt lại mật khẩu.',
      );

      return body['message']
              ?.toString() ??
          'Mã đặt lại mật khẩu đã được gửi đến email.';
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e,
          'Không thể yêu cầu đặt lại mật khẩu.',
        ),
      );
    }
  }

  // ================================================================
  // RESET PASSWORD
  // ================================================================

  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response =
          await _dio.post(
        ApiConstants.resetPassword,
        data: {
          'email':
              email.trim(),
          'code':
              code.trim(),
          'newPassword':
              newPassword,
        },
      );

      final body =
          _asMap(response.data);

      _ensureSuccess(
        body,
        'Đặt lại mật khẩu thất bại.',
      );

      return body['message']
              ?.toString() ??
          'Đặt lại mật khẩu thành công.';
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e,
          'Đặt lại mật khẩu thất bại.',
        ),
      );
    }
  }

  // ================================================================
  // GET CURRENT USER
  // ================================================================

  Future<User> getMe() async {
    try {
      final response =
          await _dio.get(
        ApiConstants.me,
      );

      final body =
          _asMap(response.data);

      _ensureSuccess(
        body,
        'Không thể lấy thông tin người dùng.',
      );

      final data =
          body['data'];

      if (data is! Map) {
        throw Exception(
          'Thông tin người dùng trả về không hợp lệ.',
        );
      }

      final user =
          User.fromJson(
        Map<String, dynamic>.from(
          data,
        ),
      );

      await StorageService.saveUserId(
        user.id,
      );

      return user;
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e,
          'Không thể lấy thông tin người dùng.',
        ),
      );
    }
  }

  // ================================================================
  // UPDATE PROFILE
  // PUT /api/auth/profile
  // ================================================================

  Future<User> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    try {
      final response =
          await _dio.put(
        ApiConstants.updateProfile,
        data: {
          'displayName':
              displayName?.trim(),
          'avatarUrl':
              avatarUrl?.trim(),
          'bio':
              bio?.trim(),
        },
      );

      final body =
          _asMap(response.data);

      _ensureSuccess(
        body,
        'Cập nhật hồ sơ thất bại.',
      );

      final data =
          body['data'];

      if (data is! Map) {
        throw Exception(
          'Thông tin hồ sơ trả về không hợp lệ.',
        );
      }

      final user =
          User.fromJson(
        Map<String, dynamic>.from(
          data,
        ),
      );

      await StorageService.saveUserId(
        user.id,
      );

      return user;
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e,
          'Cập nhật hồ sơ thất bại.',
        ),
      );
    }
  }

  // ================================================================
  // CHANGE PASSWORD
  // POST /api/auth/change-password
  // ================================================================

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      if (currentPassword.trim().isEmpty) {
        throw Exception(
          'Mật khẩu hiện tại không được để trống.',
        );
      }

      if (newPassword.isEmpty) {
        throw Exception(
          'Mật khẩu mới không được để trống.',
        );
      }

      if (newPassword.length < 6) {
        throw Exception(
          'Mật khẩu mới phải có ít nhất 6 ký tự.',
        );
      }

      if (confirmPassword != newPassword) {
        throw Exception(
          'Xác nhận mật khẩu không khớp.',
        );
      }

      final response =
          await _dio.post(
        ApiConstants.changePassword,
        data: {
          'currentPassword':
              currentPassword,
          'newPassword':
              newPassword,
          'confirmPassword':
              confirmPassword,
        },
      );

      final body =
          _asMap(response.data);

      _ensureSuccess(
        body,
        'Đổi mật khẩu thất bại.',
      );

      return body['message']
              ?.toString() ??
          'Đổi mật khẩu thành công.';
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e,
          'Đổi mật khẩu thất bại.',
        ),
      );
    }
  }

  // ================================================================
  // LOGOUT
  // ================================================================

  Future<void> logout() async {
    try {
      await _dio.post(
        ApiConstants.logout,
      );
    } on DioException {
      // JWT Stateless:
      // Dù Backend logout lỗi vẫn xóa session local.
    } finally {
      await StorageService.clearSession();
    }
  }

  // ================================================================
  // SESSION
  // ================================================================

  Future<bool> isLoggedIn() async {
    return StorageService.isLoggedIn();
  }

  Future<String?> getToken() async {
    return StorageService.getToken();
  }

  // ================================================================
  // JSON HELPERS
  // ================================================================

  Map<String, dynamic> _asMap(
    dynamic value,
  ) {
    if (value is! Map) {
      throw Exception(
        'Dữ liệu máy chủ trả về không hợp lệ.',
      );
    }

    return Map<String, dynamic>.from(
      value,
    );
  }

  void _ensureSuccess(
    Map<String, dynamic> body,
    String defaultMessage,
  ) {
    if (body['success'] != true) {
      final message =
          body['message']?.toString();

      throw Exception(
        message != null &&
                message.trim().isNotEmpty
            ? message
            : defaultMessage,
      );
    }
  }

  // ================================================================
  // ERROR HANDLER
  // ================================================================

  String _getErrorMessage(
    DioException error,
    String defaultMessage,
  ) {
    final responseData =
        error.response?.data;

    if (responseData is Map) {
      final map =
          Map<String, dynamic>.from(
        responseData,
      );

      // Backend ApiResponse message
      final message =
          map['message'] ??
          map['error'] ??
          map['title'] ??
          map['detail'];

      if (message != null &&
          message
              .toString()
              .trim()
              .isNotEmpty) {
        return message.toString();
      }

      // ASP.NET validation errors
      final errors =
          map['errors'];

      if (errors is List &&
          errors.isNotEmpty) {
        return errors
            .map(
              (error) =>
                  error.toString(),
            )
            .join('\n');
      }

      if (errors is Map &&
          errors.isNotEmpty) {
        return errors.values
            .expand(
              (value) => value is List
                  ? value
                  : [value],
            )
            .map(
              (error) =>
                  error.toString(),
            )
            .join('\n');
      }
    } else if (responseData != null) {
      final text =
          responseData
              .toString()
              .trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    // ============================================================
    // DIO ERROR TYPES
    // ============================================================

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Kết nối đến máy chủ quá thời gian.';

      case DioExceptionType.sendTimeout:
        return 'Gửi yêu cầu đến máy chủ quá thời gian.';

      case DioExceptionType.receiveTimeout:
        return 'Máy chủ phản hồi quá chậm.';

      case DioExceptionType.transformTimeout:
        return 'Xử lý dữ liệu từ máy chủ quá thời gian.';

      case DioExceptionType.connectionError:
        return 'Không thể kết nối đến máy chủ.';

      case DioExceptionType.badCertificate:
        return 'Chứng chỉ máy chủ không hợp lệ.';

      case DioExceptionType.cancel:
        return 'Yêu cầu đã bị hủy.';

      case DioExceptionType.badResponse:
        final statusCode =
            error.response?.statusCode;

        if (statusCode != null) {
          return 'Máy chủ trả về lỗi HTTP $statusCode.';
        }

        return defaultMessage;

      case DioExceptionType.unknown:
        return defaultMessage;
    }
  }
}

