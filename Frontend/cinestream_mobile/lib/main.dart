import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';

void main() {
runApp(
ChangeNotifierProvider(
create: (_) => AuthProvider(),
child: const CineStreamApp(),
),
);
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
