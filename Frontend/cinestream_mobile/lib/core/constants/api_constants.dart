class ApiConstants {
ApiConstants._();

// Android Emulator -> máy tính host
static const String baseUrl =
'http://10.0.2.2:5182/api';

// Auth
static const String login = '/auth/login';
static const String register = '/auth/register';
static const String verifyEmail = '/auth/verify-email';
static const String resendVerification =
'/auth/resend-verification';
static const String logout = '/auth/logout';
static const String forgotPassword =
'/auth/forgot-password';
static const String resetPassword =
'/auth/reset-password';
static const String me = '/auth/me';

// Movies
static const String movies = '/movies';

// Categories
static const String categories = '/categories';

// Favorites
static const String favorites = '/favorites';

// AI
static const String aiChat = '/ai/chat';
static const String aiHistory = '/ai/history';

// Payments
static const String createPayment =
'/payments/create';
static const String paymentHistory =
'/payments/history';
static const String paymentStatus =
'/payments/status';
}
