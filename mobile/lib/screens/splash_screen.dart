import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1800), _navigateNext);
  }

  void _navigateNext() {
    if (!mounted) return;
    final session = AuthService.getSavedSession();
    if (session != null && session.user != null) {
      Navigator.of(context).pushReplacement(
        RollUpPageRoute(page: HomeScreen(user: session.user!)),
      );
    } else {
      Navigator.of(context).pushReplacement(
        RollUpPageRoute(page: const WelcomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      backgroundColor: AppColors.pureWhite,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigateNext,
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -70,
              child: Container(
                width: 210,
                height: 210,
                decoration: const BoxDecoration(
                  color: AppColors.turfGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -110,
              left: -90,
              child: Container(
                width: 310,
                height: 310,
                decoration: const BoxDecoration(
                  color: AppColors.turfGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const Center(
              child: SportBookBrand(
                iconSize: 92,
                titleSize: 42,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
