class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://10.0.2.2:5000/api';

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh-token';

  static const String movies = '/movies';
  static const String series = '/series';
  static const String categories = '/categories';

  static const String favorites = '/favorites';

  static const String users = '/users';

  static const String chat = '/chat';
  static const String chatHistory = '/chat/history';
}