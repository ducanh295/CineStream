import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  // ============================================================
  // BASE URL
  // ============================================================

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5182/api';
    }

    // Android Emulator
    return 'http://10.0.2.2:5182/api';
  }

  // ============================================================
  // AUTH
  // ============================================================

  static const String login =
      '/auth/login';

  static const String register =
      '/auth/register';

  static const String verifyEmail =
      '/auth/verify-email';

  static const String resendVerification =
      '/auth/resend-verification';

  static const String logout =
      '/auth/logout';

  static const String forgotPassword =
      '/auth/forgot-password';

  static const String resetPassword =
      '/auth/reset-password';

  static const String me =
      '/auth/me';

  // Cập nhật hồ sơ cá nhân
  static const String profile =
      '/auth/profile';

  // Đổi mật khẩu
  static const String changePassword =
      '/auth/change-password';

  // ============================================================
  // MOVIES
  // ============================================================

  static const String movies =
      '/movies';

  // ============================================================
  // CATEGORIES
  // ============================================================

  static const String categories =
      '/categories';

  // ============================================================
  // FAVORITES
  // ============================================================

  static const String favorites =
      '/favorites';

  // ============================================================
  // AI
  // ============================================================

  static const String aiChat =
      '/ai/chat';

  static const String aiHistory =
      '/ai/history';

  // ============================================================
  // PAYMENTS
  // ============================================================

  // POST /api/payments/create
  static const String createPayment =
      '/payments/create';

  // GET /api/payments/history
  static const String paymentHistory =
      '/payments/history';

  // GET /api/payments/status/{orderCode}
  static const String paymentStatus =
      '/payments/status';

  // ============================================================
  // PREMIUM PLAN TYPES
  // ============================================================

  // 1 tháng
  static const String plan1Month =
      '1M';

  // 3 tháng
  static const String plan3Months =
      '3M';

  // 1 năm
  static const String plan1Year =
      '1Y';
}