import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/storage_service.dart';
import '../models/user.dart';

class AuthService {
  AuthService._();

  static final AuthService instance =
      AuthService._();

  final Dio _dio = ApiClient.instance.dio;

  // ============================================================
  // LOGIN
  // ============================================================

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

      final dynamic responseData =
          response.data;

      if (responseData is! Map) {
        throw Exception(
          'Phản hồi từ máy chủ không hợp lệ.',
        );
      }

      final data =
          Map<String, dynamic>.from(
        responseData,
      );

      if (data['success'] != true) {
        throw Exception(
          _extractMessage(data),
        );
      }

      final dynamic authData =
          data['data'];

      if (authData is! Map) {
        throw Exception(
          'Dữ liệu đăng nhập không hợp lệ.',
        );
      }

      final dynamic token =
          authData['token'];

      if (token == null ||
          token.toString().trim().isEmpty) {
        throw Exception(
          'Đăng nhập thành công nhưng không nhận được JWT token.',
        );
      }

      final dynamic userData =
          authData['user'];

      if (userData is! Map) {
        throw Exception(
          'Đăng nhập thành công nhưng không nhận được thông tin người dùng.',
        );
      }

      final user = User.fromJson(
        Map<String, dynamic>.from(
          userData,
        ),
      );

      await StorageService.saveToken(
        token.toString(),
      );

      await StorageService.saveUserId(
        user.id,
      );

      return user;
    } on DioException catch (e) {
      throw Exception(
        _handleLoginError(e),
      );
    }
  }

  // ============================================================
  // GET CURRENT USER
  // GET /api/auth/me
  // ============================================================

  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get(
        ApiConstants.me,
      );

      final dynamic responseData =
          response.data;

      if (responseData is! Map) {
        throw Exception(
          'Phản hồi từ máy chủ không hợp lệ.',
        );
      }

      final data =
          Map<String, dynamic>.from(
        responseData,
      );

      if (data['success'] != true) {
        throw Exception(
          _extractMessage(data),
        );
      }

      final dynamic userData =
          data['data'];

      if (userData is! Map) {
        throw Exception(
          'Dữ liệu tài khoản không hợp lệ.',
        );
      }

      final user = User.fromJson(
        Map<String, dynamic>.from(
          userData,
        ),
      );

      // Đồng bộ UserId vào local storage.
      await StorageService.saveUserId(
        user.id,
      );

      return user;
    } on DioException catch (e) {
      throw Exception(
        _handleCurrentUserError(e),
      );
    }
  }

  // ============================================================
  // CURRENT USER ERROR
  // ============================================================

  String _handleCurrentUserError(
    DioException e,
  ) {
    final statusCode =
        e.response?.statusCode;

    final responseData =
        e.response?.data;

    // JWT không hợp lệ / hết hạn.
    if (statusCode == 401) {
      return 'Phiên đăng nhập đã hết hạn. '
          'Vui lòng đăng nhập lại.';
    }

    // Không tìm thấy người dùng.
    if (statusCode == 404) {
      final message =
          _extractMessageFromResponse(
        responseData,
      );

      if (message.isNotEmpty) {
        return message;
      }

      return 'Không tìm thấy thông tin tài khoản.';
    }

    // Connection error.
    if (e.type ==
        DioExceptionType.connectionError) {
      return 'Không thể kết nối đến máy chủ CineStream.';
    }

    // Timeout.
    if (e.type ==
            DioExceptionType
                .connectionTimeout ||
        e.type ==
            DioExceptionType
                .sendTimeout ||
        e.type ==
            DioExceptionType
                .receiveTimeout) {
      return 'Kết nối đến máy chủ quá thời gian. '
          'Vui lòng thử lại.';
    }

    // 5xx.
    if (statusCode != null &&
        statusCode >= 500) {
      return 'Máy chủ CineStream đang gặp sự cố. '
          'Vui lòng thử lại sau.';
    }

    final message =
        _extractMessageFromResponse(
      responseData,
    );

    if (message.isNotEmpty) {
      return message;
    }

    return 'Không thể tải thông tin tài khoản. '
        'Vui lòng thử lại.';
  }

  // ============================================================
  // LOGIN ERROR
  // ============================================================

  String _handleLoginError(
    DioException e,
  ) {
    final statusCode =
        e.response?.statusCode;

    final responseData =
        e.response?.data;

    // 401: Sai tài khoản / mật khẩu
    if (statusCode == 401) {
      return 'Tài khoản hoặc mật khẩu không đúng.';
    }

    // 400: Chưa kích hoạt / bị khóa / nghiệp vụ
    if (statusCode == 400) {
      final message =
          _extractMessageFromResponse(
        responseData,
      );

      final normalized =
          _normalizeText(message);

      if (normalized.contains(
            'chua duoc kich hoat',
          ) ||
          normalized.contains(
            'chua kich hoat',
          ) ||
          normalized.contains(
            'xac minh email',
          )) {
        return 'Tài khoản chưa được kích hoạt email.';
      }

      if (normalized.contains('khoa') ||
          normalized.contains('locked')) {
        return 'Tài khoản của bạn đã bị khóa.';
      }

      if (message.isNotEmpty) {
        return message;
      }

      return 'Thông tin đăng nhập không hợp lệ.';
    }

    // Connection error.
    if (e.type ==
        DioExceptionType.connectionError) {
      return 'Không thể kết nối đến máy chủ CineStream.';
    }

    // Timeout.
    if (e.type ==
            DioExceptionType
                .connectionTimeout ||
        e.type ==
            DioExceptionType
                .sendTimeout ||
        e.type ==
            DioExceptionType
                .receiveTimeout) {
      return 'Kết nối đến máy chủ quá thời gian. '
          'Vui lòng thử lại.';
    }

    // 5xx.
    if (statusCode != null &&
        statusCode >= 500) {
      return 'Máy chủ CineStream đang gặp sự cố. '
          'Vui lòng thử lại sau.';
    }

    final message =
        _extractMessageFromResponse(
      responseData,
    );

    if (message.isNotEmpty) {
      return message;
    }

    return 'Đăng nhập thất bại. '
        'Vui lòng thử lại.';
  }

  // ============================================================
  // REGISTER
  // ============================================================

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

      final dynamic responseData =
          response.data;

      if (responseData is! Map) {
        throw Exception(
          'Phản hồi từ máy chủ không hợp lệ.',
        );
      }

      final data =
          Map<String, dynamic>.from(
        responseData,
      );

      if (data['success'] != true) {
        throw Exception(
          _extractMessage(data),
        );
      }

      final dynamic registerData =
          data['data'];

      if (registerData is! Map) {
        throw Exception(
          'Đăng ký thành công nhưng dữ liệu người dùng không hợp lệ.',
        );
      }

      final dynamic userData =
          registerData['user'];

      if (userData is! Map) {
        throw Exception(
          'Đăng ký thành công nhưng không nhận được thông tin người dùng.',
        );
      }

      return User.fromJson(
        Map<String, dynamic>.from(
          userData,
        ),
      );
    } on DioException catch (e) {
      throw Exception(
        _handleRegisterError(e),
      );
    }
  }

  // ============================================================
  // REGISTER ERROR
  // ============================================================

  String _handleRegisterError(
    DioException e,
  ) {
    final statusCode =
        e.response?.statusCode;

    final message =
        _extractMessageFromResponse(
      e.response?.data,
    );

    if (statusCode == 400) {
      if (message.isNotEmpty) {
        return message;
      }

      return 'Thông tin đăng ký không hợp lệ.';
    }

    if (statusCode == 409) {
      if (message.isNotEmpty) {
        return message;
      }

      return 'Tên đăng nhập hoặc email đã tồn tại.';
    }

    if (e.type ==
        DioExceptionType.connectionError) {
      return 'Không thể kết nối đến máy chủ CineStream.';
    }

    if (e.type ==
            DioExceptionType
                .connectionTimeout ||
        e.type ==
            DioExceptionType
                .sendTimeout ||
        e.type ==
            DioExceptionType
                .receiveTimeout) {
      return 'Kết nối đến máy chủ quá thời gian. '
          'Vui lòng thử lại.';
    }

    if (statusCode != null &&
        statusCode >= 500) {
      return 'Máy chủ CineStream đang gặp sự cố. '
          'Vui lòng thử lại sau.';
    }

    if (message.isNotEmpty) {
      return message;
    }

    return 'Đăng ký thất bại. '
        'Vui lòng thử lại.';
  }

  // ============================================================
  // VERIFY EMAIL
  // ============================================================

  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyEmail,
        data: {
          'email': email,
          'code': code,
        },
      );

      final dynamic responseData =
          response.data;

      if (responseData is! Map) {
        throw Exception(
          'Phản hồi từ máy chủ không hợp lệ.',
        );
      }

      final data =
          Map<String, dynamic>.from(
        responseData,
      );

      if (data['success'] != true) {
        throw Exception(
          _extractMessage(data),
        );
      }
    } on DioException catch (e) {
      final message =
          _extractMessageFromResponse(
        e.response?.data,
      );

      if (e.response?.statusCode == 400 &&
          message.isNotEmpty) {
        throw Exception(message);
      }

      if (e.type ==
          DioExceptionType.connectionError) {
        throw Exception(
          'Không thể kết nối đến máy chủ CineStream.',
        );
      }

      if (e.type ==
              DioExceptionType
                  .connectionTimeout ||
          e.type ==
              DioExceptionType
                  .sendTimeout ||
          e.type ==
              DioExceptionType
                  .receiveTimeout) {
        throw Exception(
          'Kết nối đến máy chủ quá thời gian. '
          'Vui lòng thử lại.',
        );
      }

      if (message.isNotEmpty) {
        throw Exception(message);
      }

      throw Exception(
        'Xác thực email thất bại. '
        'Vui lòng thử lại.',
      );
    }
  }

  // ============================================================
  // RESEND VERIFICATION EMAIL
  // ============================================================

  Future<void> resendVerificationEmail({
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.resendVerification,
        data: {
          'email': email,
        },
      );

      final dynamic responseData =
          response.data;

      if (responseData is! Map) {
        throw Exception(
          'Phản hồi từ máy chủ không hợp lệ.',
        );
      }

      final data =
          Map<String, dynamic>.from(
        responseData,
      );

      if (data['success'] != true) {
        throw Exception(
          _extractMessage(data),
        );
      }
    } on DioException catch (e) {
      final message =
          _extractMessageFromResponse(
        e.response?.data,
      );

      if (message.isNotEmpty) {
        throw Exception(message);
      }

      if (e.type ==
          DioExceptionType.connectionError) {
        throw Exception(
          'Không thể kết nối đến máy chủ CineStream.',
        );
      }

      if (e.type ==
              DioExceptionType
                  .connectionTimeout ||
          e.type ==
              DioExceptionType
                  .sendTimeout ||
          e.type ==
              DioExceptionType
                  .receiveTimeout) {
        throw Exception(
          'Kết nối đến máy chủ quá thời gian. '
          'Vui lòng thử lại.',
        );
      }

      throw Exception(
        'Không thể gửi lại mã xác thực.',
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await StorageService.clearSession();
  }

  // ============================================================
  // LOGIN STATUS
  // ============================================================

  Future<bool> isLoggedIn() async {
    return StorageService.isLoggedIn();
  }

  // ============================================================
  // GET TOKEN
  // ============================================================

  Future<String?> getToken() async {
    return StorageService.getToken();
  }

  // ============================================================
  // EXTRACT MESSAGE
  // ============================================================

  String _extractMessage(
    Map<String, dynamic> data,
  ) {
    final message = data['message'];

    if (message != null &&
        message.toString().trim().isNotEmpty) {
      return message.toString();
    }

    final errors = data['errors'];

    if (errors is List &&
        errors.isNotEmpty) {
      return errors
          .map(
            (error) => error.toString(),
          )
          .join('\n');
    }

    if (errors is Map &&
        errors.isNotEmpty) {
      final messages = <String>[];

      for (final value in errors.values) {
        if (value is List) {
          messages.addAll(
            value.map(
              (item) => item.toString(),
            ),
          );
        } else {
          messages.add(
            value.toString(),
          );
        }
      }

      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
    }

    return 'Yêu cầu thất bại.';
  }

  // ============================================================
  // EXTRACT MESSAGE FROM RESPONSE
  // ============================================================

  String _extractMessageFromResponse(
    dynamic responseData,
  ) {
    if (responseData is! Map) {
      return '';
    }

    return _extractMessage(
      Map<String, dynamic>.from(
        responseData,
      ),
    );
  }

  // ============================================================
  // NORMALIZE TEXT
  // ============================================================

  String _normalizeText(
    String value,
  ) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('đ', 'd')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ả', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ạ', 'a')
        .replaceAll('ă', 'a')
        .replaceAll('ắ', 'a')
        .replaceAll('ằ', 'a')
        .replaceAll('ẳ', 'a')
        .replaceAll('ẵ', 'a')
        .replaceAll('ặ', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ấ', 'a')
        .replaceAll('ầ', 'a')
        .replaceAll('ẩ', 'a')
        .replaceAll('ẫ', 'a')
        .replaceAll('ậ', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ẻ', 'e')
        .replaceAll('ẽ', 'e')
        .replaceAll('ẹ', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ế', 'e')
        .replaceAll('ề', 'e')
        .replaceAll('ể', 'e')
        .replaceAll('ễ', 'e')
        .replaceAll('ệ', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ỉ', 'i')
        .replaceAll('ĩ', 'i')
        .replaceAll('ị', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ỏ', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ọ', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ố', 'o')
        .replaceAll('ồ', 'o')
        .replaceAll('ổ', 'o')
        .replaceAll('ỗ', 'o')
        .replaceAll('ộ', 'o')
        .replaceAll('ơ', 'o')
        .replaceAll('ớ', 'o')
        .replaceAll('ờ', 'o')
        .replaceAll('ở', 'o')
        .replaceAll('ỡ', 'o')
        .replaceAll('ợ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ủ', 'u')
        .replaceAll('ũ', 'u')
        .replaceAll('ụ', 'u')
        .replaceAll('ư', 'u')
        .replaceAll('ứ', 'u')
        .replaceAll('ừ', 'u')
        .replaceAll('ử', 'u')
        .replaceAll('ữ', 'u')
        .replaceAll('ự', 'u')
        .replaceAll('ý', 'y')
        .replaceAll('ỳ', 'y')
        .replaceAll('ỷ', 'y')
        .replaceAll('ỹ', 'y')
        .replaceAll('ỵ', 'y');
  }
}