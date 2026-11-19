import 'package:flutter/material.dart';

void main() {
  runApp(const SwapitApp());
}

// ألوان تصميم Swapit AI
class AppColors {
  static const Color background = Color(0xFFFAF9F4); // كريمي فاتح
  static const Color primary = Color(0xFF1E2723); // أخضر غامق جدًا
  static const Color secondary = Color(0xFF4C6453); // أخضر هادي
  static const Color error = Color(0xFFBA1A1A); // أحمر للأخطاء
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
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Swapit AI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'بدّل اللي مركون عندك بحاجة نفسك فيها.',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.6,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}