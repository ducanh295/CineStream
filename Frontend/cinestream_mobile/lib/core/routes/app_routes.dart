import 'package:flutter/material.dart';

import '../../models/movie.dart';

// ============================================================
// AUTH
// ============================================================

import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';

// ============================================================
// MAIN SCREENS
// ============================================================

import '../../screens/category/category_screen.dart';
import '../../screens/chatbot/chatbot_screen.dart';
import '../../screens/favorites/favorites_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/movie/movie_detail_screen.dart';
import '../../screens/player/video_player_screen.dart';
import '../../screens/profile/change_password_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/splash/splash_screen.dart';

// ============================================================
// PAYMENT
// ============================================================

import '../../screens/Payment/premium_screen.dart';

class AppRoutes {
  AppRoutes._();

  // ============================================================
  // ROUTE NAMES
  // ============================================================

  static const String splash = '/';

  static const String home = '/home';

  static const String search = '/search';

  static const String category = '/category';

  static const String chatbot = '/chatbot';

  static const String profile = '/profile';

  static const String favorites = '/favorites';

  static const String editProfile = '/edit-profile';

  static const String changePassword = '/change-password';

  static const String premium = '/premium';

  static const String login = '/login';

  static const String register = '/register';

  static const String forgotPassword = '/forgot-password';

  static const String movieDetail = '/movie-detail';

  static const String player = '/player';

  // ============================================================
  // ROUTES MAP
  // ============================================================

  static final Map<String, WidgetBuilder> routes = {
    // ----------------------------------------------------------
    // SPLASH
    // ----------------------------------------------------------

    splash: (context) => const SplashScreen(),

    // ----------------------------------------------------------
    // HOME
    // ----------------------------------------------------------

    home: (context) => const HomeScreen(),

    // ----------------------------------------------------------
    // SEARCH
    // ----------------------------------------------------------

    search: (context) => const SearchScreen(),

    // ----------------------------------------------------------
    // CATEGORY
    // ----------------------------------------------------------

    category: (context) => const CategoryScreen(),

    // ----------------------------------------------------------
    // AI CHATBOT
    // ----------------------------------------------------------

    chatbot: (context) => const ChatbotScreen(),

    // ----------------------------------------------------------
    // PROFILE
    // ----------------------------------------------------------

    profile: (context) => const ProfileScreen(),

    // ----------------------------------------------------------
    // FAVORITES
    // ----------------------------------------------------------

    favorites: (context) => const FavoritesScreen(),

    // ----------------------------------------------------------
    // EDIT PROFILE
    // ----------------------------------------------------------

    editProfile: (context) => const EditProfileScreen(),

    // ----------------------------------------------------------
    // CHANGE PASSWORD
    // ----------------------------------------------------------

    changePassword: (context) => const ChangePasswordScreen(),

    // ----------------------------------------------------------
    // PREMIUM
    // ----------------------------------------------------------

    premium: (context) => const PremiumScreen(),

    // ----------------------------------------------------------
    // LOGIN
    // ----------------------------------------------------------

    login: (context) => const LoginScreen(),

    // ----------------------------------------------------------
    // REGISTER
    // ----------------------------------------------------------

    register: (context) => const RegisterScreen(),

    // ----------------------------------------------------------
    // FORGOT PASSWORD
    // ----------------------------------------------------------

    forgotPassword: (context) =>
        const ForgotPasswordScreen(),

    // ----------------------------------------------------------
    // MOVIE DETAIL
    // ----------------------------------------------------------

    movieDetail: (context) {
      final arguments =
          ModalRoute.of(context)?.settings.arguments;

      if (arguments is Movie) {
        return MovieDetailScreen(
          movie: arguments,
        );
      }

      return const HomeScreen();
    },

    // ----------------------------------------------------------
    // VIDEO PLAYER
    // ----------------------------------------------------------

    player: (context) {
      final arguments =
          ModalRoute.of(context)?.settings.arguments;

      if (arguments is Movie) {
        return VideoPlayerScreen(
          movie: arguments,
        );
      }

      return const HomeScreen();
    },
  };
}

