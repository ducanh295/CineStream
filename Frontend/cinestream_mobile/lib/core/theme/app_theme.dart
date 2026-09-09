import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFFF5F0E6);
  static const Color darkGreen = Color(0xFF174D3C);
  static const Color darkGreen2 = Color(0xFF0F382C);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF171717);
  static const Color grey = Color(0xFF777777);
  static const Color lightGrey = Color(0xFFE8E2D8);
  static const Color pink = Color(0xFFF7D8D8);
  static const Color red = Color(0xFFC94D4D);
  static const Color yellow = Color(0xFFF2C94C);

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',

      colorScheme: ColorScheme.fromSeed(
        seedColor: darkGreen,
        brightness: Brightness.light,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: black,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        hintStyle: const TextStyle(
          color: grey,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: darkGreen,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}