import 'package:flutter/material.dart';

import '../../models/movie.dart';

import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/verify_email_screen.dart';
import '../../screens/category/category_screen.dart';
import '../../screens/chatbot/chatbot_screen.dart';
import '../../screens/favorite/favorite_screen.dart';
import '../../screens/featured/featured_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/movie/movie_detail_screen.dart';
import '../../screens/player/video_player_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/support/support_screen.dart';

class AppRoutes {
  AppRoutes._();

  // ============================================================
  // ROUTES
  // ============================================================

  static const String splash = '/';

  static const String home = '/home';

  static const String search = '/search';

  static const String category = '/category';

  static const String chatbot = '/chatbot';

  static const String profile = '/profile';

  static const String featured = '/featured';

  static const String favorite = '/favorite';

  static const String support = '/support';

  static const String login = '/login';

  static const String register = '/register';

  static const String verifyEmail =
      '/verify-email';

  static const String movieDetail =
      '/movie-detail';

  static const String player = '/player';

  // ============================================================
  // ROUTE MAP
  // ============================================================

  static final Map<String, WidgetBuilder> routes = {
    splash: (context) {
      return const SplashScreen();
    },

    home: (context) {
      return const HomeScreen();
    },

    search: (context) {
      return const SearchScreen();
    },

    category: (context) {
      return const CategoryScreen();
    },

    chatbot: (context) {
      return const ChatbotScreen();
    },

    profile: (context) {
      return const ProfileScreen();
    },

    featured: (context) {
      return const FeaturedScreen();
    },

    favorite: (context) {
      return const FavoriteScreen();
    },

    support: (context) {
      return const SupportScreen();
    },

    login: (context) {
      return const LoginScreen();
    },

    register: (context) {
      return const RegisterScreen();
    },

    // ==========================================================
    // VERIFY EMAIL
    // ==========================================================

    verifyEmail: (context) {
      final arguments =
          ModalRoute.of(context)
              ?.settings
              .arguments;

      if (arguments is String &&
          arguments.trim().isNotEmpty) {
        return VerifyEmailScreen(
          email: arguments,
        );
      }

      return const RegisterScreen();
    },

    // ==========================================================
    // MOVIE DETAIL
    // ==========================================================

    movieDetail: (context) {
      final arguments =
          ModalRoute.of(context)
              ?.settings
              .arguments;

      if (arguments is Movie) {
        return MovieDetailScreen(
          movie: arguments,
        );
      }

      return const HomeScreen();
    },

    // ==========================================================
    // VIDEO PLAYER
    // ==========================================================

    player: (context) {
      final arguments =
          ModalRoute.of(context)
              ?.settings
              .arguments;

      if (arguments is Movie) {
        return VideoPlayerScreen(
          movie: arguments,
        );
      }

      return const HomeScreen();
    },
  };
} 