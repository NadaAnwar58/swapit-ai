import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_screen.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gpjmhdtxxieyxxoirxtt.supabase.co',
    anonKey: 'sb_publishable_po9WQwFIctursSN-_10Z4Q_VOCeNdZO',
  );

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