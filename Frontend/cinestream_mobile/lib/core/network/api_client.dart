import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../storage/storage_service.dart';

class ApiClient {
  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout:
            const Duration(seconds: 15),
        receiveTimeout:
            const Duration(seconds: 30),
        sendTimeout:
            const Duration(seconds: 15),
        headers: {
          'Content-Type':
              'application/json',
          'Accept':
              'application/json',
        },
        responseType:
            ResponseType.json,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        // ========================================================
        // REQUEST
        // ========================================================

        onRequest: (
          options,
          handler,
        ) async {
          try {
            final token =
                await StorageService.getToken();

            if (token != null &&
                token.trim().isNotEmpty) {
              options.headers['Authorization'] =
                  'Bearer ${token.trim()}';
            }

            handler.next(options);
          } catch (_) {
            // Nếu lấy token thất bại,
            // vẫn cho request tiếp tục.
            handler.next(options);
          }
        },

        // ========================================================
        // RESPONSE
        // ========================================================

        onResponse: (
          response,
          handler,
        ) {
          handler.next(response);
        },

        // ========================================================
        // ERROR
        // ========================================================

        onError: (
          error,
          handler,
        ) async {
          final statusCode =
              error.response?.statusCode;

          // Backend trả 401 => JWT không còn hợp lệ
          if (statusCode == 401) {
            await _handleUnauthorized();
          }

          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance =
      ApiClient._internal();

  late final Dio dio;

  // ============================================================
  // HANDLE 401
  // ============================================================

  Future<void> _handleUnauthorized() async {
    try {
      await StorageService.clearSession();
    } catch (_) {
      // Không để lỗi clear session
      // làm crash ứng dụng.
    }
  }
}