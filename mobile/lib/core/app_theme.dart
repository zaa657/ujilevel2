import 'package:flutter/material.dart';

class AppColors {
  static const Color turfGreen = Color(0xFF4ADE80);
  static const Color turfGreenDark = Color(0xFF16A34A);
  static const Color courtInk = Color(0xFF111827);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color canvasBg = Color(0xFFECFDF5);
  static const Color fieldMist = Color(0xFFF3F4F6);
  static const Color textMuted = Color(0xFF374151);
  static const Color borderSubtle = Color(0xFFD1D5DB);
  static const Color errorSurface = Color(0xFFFEE2E2);
  static const Color errorInk = Color(0xFF991B1B);
}

InputDecoration authInputDecoration({
  required String hintText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(
      color: AppColors.textMuted,
      fontWeight: FontWeight.w400,
    ),
    filled: true,
    fillColor: AppColors.fieldMist,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: const BorderSide(color: AppColors.borderSubtle),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: const BorderSide(color: AppColors.borderSubtle),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: const BorderSide(color: AppColors.courtInk, width: 2),
    ),
  );
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.pureWhite,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ClipRect(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.courtInk.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class SportBookBrand extends StatelessWidget {
  final double iconSize;
  final double titleSize;
  final String logoAssetPath;

  const SportBookBrand({
    super.key,
    this.iconSize = 84,
    this.titleSize = 40,
    this.logoAssetPath = 'assets/images/logo.png',
  });

  @override
  Widget build(BuildContext context) {
    if (logoAssetPath.isEmpty) {
      return const SizedBox.shrink();
    }

    return Image.asset(
      logoAssetPath,
      width: iconSize * 2.8,
      height: iconSize * 1.1,
      fit: BoxFit.contain,
      semanticLabel: 'SportsBook',
    );
  }
}
