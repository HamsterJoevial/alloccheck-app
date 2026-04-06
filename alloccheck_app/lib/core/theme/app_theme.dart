import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Couleurs principales — bleu confiance + vert succès
  static const Color primary = Color(0xFF1A56DB); // Bleu CAF / institutionnel
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color secondary = Color(0xFF059669); // Vert succès / argent récupéré
  static const Color secondaryLight = Color(0xFF10B981);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color background = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);

  // Couleurs par aide
  static const Map<String, Color> aideColors = {
    'rsa': Color(0xFF7C3AED),
    'apl': Color(0xFF2563EB),
    'prime_activite': Color(0xFF059669),
    'af': Color(0xFFD97706),
    'aah': Color(0xFFDB2777),
    'cmg': Color(0xFF0891B2),
    'paje': Color(0xFF0D9488),
    'cf': Color(0xFFEA580C),
    'prepare': Color(0xFF7C3AED),
    'ars': Color(0xFFDC2626),
  };

  static const Map<String, String> aideLabels = {
    'rsa': 'RSA',
    'apl': 'APL',
    'prime_activite': 'Prime d\'activité',
    'af': 'Allocations familiales',
    'aah': 'AAH',
    'cmg': 'CMG',
    'paje': 'PAJE (base)',
    'cf': 'Complément familial',
    'prepare': 'PreParE',
    'ars': 'ARS (rentrée scolaire)',
  };

  static const Map<String, IconData> aideIcons = {
    'rsa': Icons.account_balance_wallet,
    'apl': Icons.home,
    'prime_activite': Icons.trending_up,
    'af': Icons.family_restroom,
    'aah': Icons.accessibility_new,
    'cmg': Icons.child_care,
    'paje': Icons.baby_changing_station,
    'cf': Icons.people,
    'prepare': Icons.self_improvement,
    'ars': Icons.school,
  };

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        error: error,
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
        color: background,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
    );
  }
}
