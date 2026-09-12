import 'package:flutter/material.dart';

import '../../models/movie.dart';

import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/category/category_screen.dart';
import '../../screens/chatbot/chatbot_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/movie/movie_detail_screen.dart';
import '../../screens/player/video_player_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/splash/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String home = '/home';
  static const String search = '/search';
  static const String category = '/category';
  static const String chatbot = '/chatbot';
  static const String profile = '/profile';
  static const String login = '/login';
  static const String register = '/register';
  static const String movieDetail = '/movie-detail';
  static const String player = '/player';

  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),

    home: (context) => const HomeScreen(),

    search: (context) => const SearchScreen(),

    category: (context) => const CategoryScreen(),

    chatbot: (context) => const ChatbotScreen(),

    profile: (context) => const ProfileScreen(),

    login: (context) => const LoginScreen(),

    register: (context) => const RegisterScreen(),

    movieDetail: (context) {
      final arguments = ModalRoute.of(context)?.settings.arguments;

      if (arguments is Movie) {
        return MovieDetailScreen(
          movie: arguments,
        );
      }

      return const HomeScreen();
    },

    player: (context) {
      final arguments = ModalRoute.of(context)?.settings.arguments;

      if (arguments is Movie) {
        return VideoPlayerScreen(
          movie: arguments,
        );
      }

      return const HomeScreen();
    },
  };
}