import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFFF6F43);      // Warm Coral / Foodie Orange
  static const Color primaryDark = Color(0xFFE64A19);
  static const Color secondaryColor = Color(0xFFFFB300);    // Warm Gold / Honey
  static const Color backgroundColor = Color(0xFFFBF8F5);   // Soft Warm White
  static const Color surfaceColor = Colors.white;
  static const Color cardBorderColor = Color(0xFFF0EBE5);
  static const Color textPrimary = Color(0xFF1E2124);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentBlue = Color(0xFF3B82F6);

  static const Color primary = primaryColor;
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = primaryColor;
  static const Color primaryFixed = Color(0xFFFFE1D8);
  static const Color primaryFixedDim = Color(0xFFFFB59D);
  static const Color onPrimaryFixed = Color(0xFF4A1608);
  static const Color onPrimaryFixedVariant = Color(0xFF7A2D18);
  static const Color secondary = secondaryColor;
  static const Color secondaryContainer = Color(0xFFFFE7AD);
  static const Color onSecondaryContainer = Color(0xFF4A3500);
  static const Color secondaryMint = accentGreen;
  static const Color tertiaryFixed = Color(0xFFD8F3E8);
  static const Color onTertiaryFixed = Color(0xFF124734);
  static const Color tertiaryAmber = secondaryColor;
  static const Color surface = surfaceColor;
  static const Color surfaceContainer = Color(0xFFF7F2ED);
  static const Color surfaceContainerLow = Color(0xFFFAF7F3);
  static const Color surfaceContainerLowest = Colors.white;
  static const Color onSurface = textPrimary;
  static const Color onSurfaceVariant = textSecondary;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorderColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
