class ApiConstants {
  ApiConstants._();

  // ==========================================================
  // BASE URL
  // ==========================================================

  // Android Emulator:
  // 10.0.2.2 trỏ về máy Windows đang chạy Backend.
  static const String baseUrl =
      'http://10.0.2.2:5182/api';

  // ==========================================================
  // AUTH
  // ==========================================================

  static const String login =
      '/auth/login';

  static const String register =
      '/auth/register';

  static const String refreshToken =
      '/auth/refresh-token';

  static const String verifyEmail =
      '/auth/verify-email';

  static const String resendVerification =
      '/auth/resend-verification';

  static const String me =
      '/auth/me';

  // ==========================================================
  // MOVIES
  // ==========================================================

  static const String movies =
      '/movies';

  // ==========================================================
  // SERIES
  // ==========================================================

  static const String series =
      '/series';

  // ==========================================================
  // CATEGORIES
  // ==========================================================

  static const String categories =
      '/categories';

  // ==========================================================
  // FAVORITES
  // ==========================================================

  static const String favorites =
      '/favorites';

  // ==========================================================
  // USERS
  // ==========================================================

  static const String users =
      '/users';

  // ==========================================================
  // CHAT
  // ==========================================================

  static const String chat =
      '/chat';

  static const String chatHistory =
      '/chat/history';
}