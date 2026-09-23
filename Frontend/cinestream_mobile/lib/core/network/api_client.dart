import 'dart:io';
import 'package:dio/io.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../constants/api_constants.dart';
import '../storage/storage_service.dart';

class ApiClient {
  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Cho phép chấp nhận chứng chỉ Dev tự ký
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };

    dio.interceptors.add(
      InterceptorsWrapper(
        // ============================================================
        // REQUEST
        // ============================================================

        onRequest: (options, handler) async {
          final token = await StorageService.getToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },

        // ============================================================
        // ERROR
        // ============================================================

        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _handleUnauthorized();
          }

          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio dio;

  // ================================================================
  // GLOBAL NAVIGATOR
  // ================================================================

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // ================================================================
  // AUTH PROVIDER CALLBACK
  // ================================================================

  VoidCallback? _unauthorizedHandler;

  void setUnauthorizedHandler(VoidCallback handler) {
    _unauthorizedHandler = handler;
  }

  // ================================================================
  // 401 CONTROL
  // ================================================================

  bool _isHandlingUnauthorized = false;

  Future<void> _handleUnauthorized() async {
    // Nếu nhiều request cùng lúc trả 401,
    // chỉ xử lý request đầu tiên.
    if (_isHandlingUnauthorized) {
      return;
    }

    _isHandlingUnauthorized = true;

    try {
      // ------------------------------------------------------------
      // 1. XÓA JWT + USER ID
      // ------------------------------------------------------------

      await StorageService.clearSession();

      // ------------------------------------------------------------
      // 2. RESET AUTH PROVIDER
      // ------------------------------------------------------------

      _unauthorizedHandler?.call();

      // ------------------------------------------------------------
      // 3. ĐIỀU HƯỚNG VỀ LOGIN
      // ------------------------------------------------------------

      final navigator = navigatorKey.currentState;

      if (navigator == null) {
        return;
      }

      // Xóa sạch các SnackBar còn tồn đọng từ màn hình trước đó tránh rò rỉ sang màn hình Đăng nhập
      final currentContext = navigatorKey.currentContext;
      if (currentContext != null && currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).clearSnackBars();
      }

      // Xóa toàn bộ stack cũ.
      // Người dùng không thể bấm Back quay lại màn hình
      // đang sử dụng token đã hết hạn.
      navigator.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } finally {
      _isHandlingUnauthorized = false;
    }
  }
}

