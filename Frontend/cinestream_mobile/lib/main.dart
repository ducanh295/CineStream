import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const CineStreamApp());
}

class CineStreamApp extends StatelessWidget {
  const CineStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CineStream',
      theme: AppTheme.lightTheme(),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}