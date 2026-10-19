import 'package:flutter/material.dart';

/// Design tokens extracted directly from Stitch project "Food Decider Flutter UI" (Culinary Companion)
class AppTheme {
  // Brand Primary & Coral
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryDark = Color(0xFFAB3500);
  static const Color primaryContainer = Color(0xFFFF6B35);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFFFDBD0);
  static const Color primaryFixedDim = Color(0xFFFFB59D);
  static const Color onPrimaryFixed = Color(0xFF390C00);
  static const Color onPrimaryFixedVariant = Color(0xFF832600);

  // Secondary & Mint Fresh
  static const Color secondary = Color(0xFF006A62);
  static const Color secondaryMint = Color(0xFF2EC4B6);
  static const Color secondaryContainer = Color(0xFF70F8E8);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF007168);

  // Tertiary & Warm Amber
  static const Color tertiary = Color(0xFF865300);
  static const Color tertiaryAmber = Color(0xFFFFA200);
  static const Color tertiaryContainer = Color(0xFFD78800);
  static const Color tertiaryFixed = Color(0xFFFFDDB9);
  static const Color tertiaryFixedDim = Color(0xFFFFB962);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF492B00);
  static const Color onTertiaryFixed = Color(0xFF2B1700);

  // Surface & Neutrals
  static const Color background = Color(0xFFF8F9FF);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceDim = Color(0xFFD6DAE4);
  static const Color surfaceBright = Color(0xFFF8F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF0F4FD);
  static const Color surfaceContainer = Color(0xFFEAEEF8);
  static const Color surfaceContainerHigh = Color(0xFFE4E8F2);
  static const Color surfaceContainerHighest = Color(0xFFDEE2EC);

  static const Color onSurface = Color(0xFF171C23);
  static const Color onSurfaceVariant = Color(0xFF594139);
  static const Color outline = Color(0xFF8D7168);
  static const Color outlineVariant = Color(0xFFE1BFB5);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);

  // Legacy mappings for backwards compatibility
  static const Color primaryColor = primary;
  static const Color secondaryColor = tertiaryAmber;
  static const Color backgroundColor = background;
  static const Color surfaceColor = surfaceContainerLowest;
  static const Color cardBorderColor = outlineVariant;
  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color accentGreen = secondaryMint;
  static const Color accentBlue = Color(0xFF3B82F6);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Plus Jakarta Sans',
      fontFamilyFallback: const ['Roboto', 'sans-serif'],
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryFixed,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: Color(0xFF93000A),
        surface: surface,
        onSurface: onSurface,
        surfaceContainerLowest: surfaceContainerLowest,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainer: surfaceContainer,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainerHighest: surfaceContainerHighest,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 1,
        shadowColor: const Color(0x15FF6B35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x10000000), width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 2,
          shadowColor: const Color(0x4DFF6B35),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
