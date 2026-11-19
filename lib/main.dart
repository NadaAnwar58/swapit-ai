import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const SwapitApp());
}

class SwapitApp extends StatelessWidget {
  const SwapitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swapit AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.background,
          secondary: AppColors.secondary,
          surface: AppColors.background,
          error: AppColors.error,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}