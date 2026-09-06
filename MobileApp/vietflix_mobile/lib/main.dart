import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const VietFlixApp());
}

class VietFlixApp extends StatelessWidget {
  const VietFlixApp({super.key});

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