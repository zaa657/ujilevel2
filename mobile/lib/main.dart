import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const SportBookApp());
}

class SportBookApp extends StatelessWidget {
  const SportBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SportBook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.pureWhite,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.turfGreen,
          primary: AppColors.courtInk,
          surface: AppColors.pureWhite,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
