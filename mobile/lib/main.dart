import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'models/lapangan_model.dart';
import 'models/user_model.dart';
import 'screens/home_screen.dart';
import 'screens/lapangan_detail_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const SportBookApp());
}

class SportBookApp extends StatelessWidget {
  const SportBookApp({super.key});

  static Widget resolveInitialScreen() {
    final page = Uri.base.queryParameters['page']?.toLowerCase();
    const penyewa = UserModel(
      id: 6,
      name: 'Reyza Penyewa',
      email: 'reyza@sportbook.id',
      role: 'penyewa',
    );
    const admin = UserModel(
      id: 1,
      name: 'Admin SportBook',
      email: 'admin@sportbook.id',
      role: 'admin',
    );

    const sampleLapangan = LapanganModel(
      id: 9,
      idKategori: 5,
      namaLapangan: 'Kennington Oval Sports Arena',
      jenisOlahraga: 'Basket',
      hargaPerJam: 145000,
      deskripsi:
          '100% on-ground staff vaccinated. Lapangan basket outdoor multifungsi berlatar pemandangan terbuka terinspirasi Kennington Oval.',
      fotoLapangan: '/uploads/kennington-oval-sports-arena.jpg',
    );

    switch (page) {
      case 'welcome':
        return const WelcomeScreen();
      case 'login':
        return const LoginScreen();
      case 'register':
        return const RegisterScreen();
      case 'catalog':
      case 'home':
        return const HomeScreen(user: penyewa, initialTabIndex: 0);
      case 'bookings':
      case 'my_bookings':
        return const HomeScreen(user: penyewa, initialTabIndex: 2);
      case 'detail':
      case 'booking_form':
        return const LapanganDetailScreen(lapangan: sampleLapangan);
      case 'admin':
      case 'admin_dashboard':
        return const HomeScreen(user: admin);
      default:
        return const SplashScreen();
    }
  }

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
      home: resolveInitialScreen(),
    );
  }
}
