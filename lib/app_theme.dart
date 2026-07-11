import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central place for all colors/text styles so every screen looks consistent.
/// keyword-chip accent, light grey image placeholders.
class AppColors {
  static const Color primary = Color(0xFF16337A); // navy blue (Login/Next buttons)
  static const Color primaryDark = Color(0xFF0E2454);
  static const Color accent = Color.fromARGB(255, 255, 253, 120); // yellow (Get Started / chips)
  static const Color background = Color(0xFFFFFFFF);
  static const Color placeholder = Color(0xFFE6E7EA); // grey image boxes
  static const Color chipGrey = Color(0xFFEDEDED);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color success = Color(0xFF2E8B57);
  static const Color danger = Color(0xFFE24C4C);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.accent,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.placeholder.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      useMaterial3: true,
    );
  }
}