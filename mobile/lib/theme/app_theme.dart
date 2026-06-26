import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const navy = Color(0xFF0D3A6E);
  static const navy2 = Color(0xFF1A56A0);
  static const navy3 = Color(0xFFD6E4F7);
  static const navyLight = Color(0xFFEBF2FB);
  static const orange = Color(0xFFE87722);
  static const orangeLight = Color(0xFFFDE9D4);
  static const green = Color(0xFF1D9E75);
  static const greenLight = Color(0xFFE1F5EE);
  static const red = Color(0xFFE24B4A);
  static const redLight = Color(0xFFFCEBEB);
  static const gray1 = Color(0xFFF8F9FC);
  static const gray2 = Color(0xFFEEF1F7);
  static const gray3 = Color(0xFFD1D9E8);
  static const gray4 = Color(0xFF8896B3);
  static const textMain = Color(0xFF1A2340);
  static const textSub = Color(0xFF5A6A8A);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy),
        scaffoldBackgroundColor: AppColors.gray1,
        textTheme: GoogleFonts.dmSansTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.gray2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.navy2, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );
}
