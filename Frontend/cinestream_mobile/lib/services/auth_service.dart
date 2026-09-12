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


  final body = _asMap(response.data);

  _ensureSuccess(
    body,
    'Đăng nhập thất bại.',
  );

  final data = _asMap(body['data']);

  final token = data['token']?.toString();

  if (token == null || token.isEmpty) {
    throw Exception(
      'Đăng nhập thành công nhưng không nhận được JWT token.',
    );
  }

  final userJson = data['user'];

  if (userJson is! Map) {
    throw Exception(
      'Không nhận được thông tin người dùng.',
    );
  }

  final user = User.fromJson(
    Map<String, dynamic>.from(userJson),
  );

  await StorageService.saveToken(token);
  await StorageService.saveUserId(user.id);

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

Future<String> register({
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


  final body = _asMap(response.data);

  _ensureSuccess(
    body,
    'Đăng ký thất bại.',
  );

  return body['message']?.toString() ??
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

Future<String> verifyEmail({
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


  final body = _asMap(response.data);

  _ensureSuccess(
    body,
    'Xác minh email thất bại.',
  );

  return body['message']?.toString() ??
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

Future<String> resendVerification({
required String email,
}) async {
try {
final response = await _dio.post(
ApiConstants.resendVerification,
data: {
'email': email,
},
);


  final body = _asMap(response.data);

  _ensureSuccess(
    body,
    'Không thể gửi lại mã xác minh.',
  );

  return body['message']?.toString() ??
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

Future<String> forgotPassword({
required String email,
}) async {
try {
final response = await _dio.post(
ApiConstants.forgotPassword,
data: {
'email': email,
},
);


  final body = _asMap(response.data);

  _ensureSuccess(
    body,
    'Không thể yêu cầu đặt lại mật khẩu.',
  );

  return body['message']?.toString() ??
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

Future<String> resetPassword({
required String email,
required String code,
required String newPassword,
}) async {
try {
final response = await _dio.post(
ApiConstants.resetPassword,
data: {
'email': email,
'code': code,
'newPassword': newPassword,
},
);


  final body = _asMap(response.data);

  _ensureSuccess(
    body,
    'Đặt lại mật khẩu thất bại.',
  );

  return body['message']?.toString() ??
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

Future<User> getMe() async {
try {
final response = await _dio.get(
ApiConstants.me,
);


  final body = _asMap(response.data);

  _ensureSuccess(
    body,
    'Không thể lấy thông tin người dùng.',
  );

  final data = body['data'];

  if (data is! Map) {
    throw Exception(
      'Thông tin người dùng trả về không hợp lệ.',
    );
  }

  final user = User.fromJson(
    Map<String, dynamic>.from(data),
  );

  await StorageService.saveUserId(user.id);

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

Future<void> logout() async {
try {
await _dio.post(
ApiConstants.logout,
);
} on DioException {
// Dù API logout thất bại, vẫn xóa session local.
} finally {
await StorageService.clearSession();
}
}

Future<bool> isLoggedIn() async {
return StorageService.isLoggedIn();
}

Future<String?> getToken() async {
return StorageService.getToken();
}

Map<String, dynamic> _asMap(dynamic value) {
if (value is! Map) {
throw Exception(
'Dữ liệu máy chủ trả về không hợp lệ.',
);
}


return Map<String, dynamic>.from(value);


}

void _ensureSuccess(
Map<String, dynamic> body,
String defaultMessage,
) {
if (body['success'] != true) {
throw Exception(
body['message']?.toString() ??
defaultMessage,
);
}
}

String _getErrorMessage(
DioException error,
String defaultMessage,
) {
final responseData = error.response?.data;


if (responseData is Map) {
  final message = responseData['message'];

  if (message != null &&
      message.toString().trim().isNotEmpty) {
    return message.toString();
  }

  final errors = responseData['errors'];

  if (errors is List && errors.isNotEmpty) {
    return errors
        .map((error) => error.toString())
        .join('\n');
  }

  if (errors is Map && errors.isNotEmpty) {
    return errors.values
        .expand(
          (value) => value is List
              ? value
              : [value],
        )
        .map((error) => error.toString())
        .join('\n');
  }
}

switch (error.type) {
  case DioExceptionType.connectionTimeout:
  case DioExceptionType.sendTimeout:
  case DioExceptionType.receiveTimeout:
    return 'Kết nối đến máy chủ quá thời gian.';

  case DioExceptionType.connectionError:
    return 'Không thể kết nối đến máy chủ.';

  case DioExceptionType.badCertificate:
    return 'Chứng chỉ máy chủ không hợp lệ.';

  case DioExceptionType.cancel:
    return 'Yêu cầu đã bị hủy.';

  default:
    return defaultMessage;
}


}
}
