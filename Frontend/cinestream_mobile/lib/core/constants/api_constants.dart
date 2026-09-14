import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  // ================================================================
  // BASE URL
  // ================================================================

  // Tự động chọn địa chỉ Backend theo nền tảng:
  //
  // Web / Chrome:
  //   http://localhost:5182/api
  //
  // Android Emulator:
  //   http://10.0.2.2:5182/api
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5182/api';
    }

    return 'http://10.0.2.2:5182/api';
  }

  // ================================================================
  // AUTH
  // ================================================================

  // Đăng nhập
  static const String login =
      '/auth/login';

  // Đăng ký
  static const String register =
      '/auth/register';

  // Xác thực email bằng OTP
  static const String verifyEmail =
      '/auth/verify-email';

  // Gửi lại OTP xác thực email
  static const String resendVerification =
      '/auth/resend-verification';

  // Đăng xuất
  static const String logout =
      '/auth/logout';

  // Quên mật khẩu
  static const String forgotPassword =
      '/auth/forgot-password';

  // Đặt lại mật khẩu bằng OTP
  static const String resetPassword =
      '/auth/reset-password';

  // Lấy thông tin user hiện tại
  static const String me =
      '/auth/me';

  // Cập nhật Profile
  static const String updateProfile =
      '/auth/profile';

  // Đổi mật khẩu
  static const String changePassword =
      '/auth/change-password';

  // ================================================================
  // MOVIES
  // ================================================================

  static const String movies =
      '/movies';

  // ================================================================
  // CATEGORIES
  // ================================================================

  static const String categories =
      '/categories';

  // ================================================================
  // FAVORITES
  // ================================================================

  static const String favorites =
      '/favorites';

  // ================================================================
  // AI CINEBOT
  // ================================================================

  static const String aiChat =
      '/ai/chat';

  static const String aiHistory =
      '/ai/history';

  // ================================================================
  // PAYMENTS / PREMIUM
  // ================================================================

  // Tạo đơn thanh toán Premium
  static const String createPayment =
      '/payments/create';

  // Lịch sử thanh toán
  static const String paymentHistory =
      '/payments/history';

  // Kiểm tra trạng thái đơn hàng:
  // /payments/status/{orderCode}
  static const String paymentStatus =
      '/payments/status';
}

