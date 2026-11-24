import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Base design tokens for iOS Liquid Glass / Crystal aesthetics with adaptive
/// Light & Dark mode support and exact official Renfe & ADIF palettes.
abstract final class AppTheme {
  // Exact Renfe Corporate Colors
  static const Color renfePrimary = Color(0xFF680A51);
  static const Color renfeSecondary = Color(0xFF8E136F);
  static const Color renfeAccent = Color(0xFFE20074);

  // Exact ADIF Official Corporate Palette
  static const Color adifPrimary =
      Color(0xFF006338); // Dark Green (Headers/Brand)
  static const Color adifTeal =
      Color(0xFF007861); // Teal Green (Buttons/UI support)
  static const Color adifLime =
      Color(0xFFC4D600); // Lime Green (Highlights/accents)
  static const Color adifMint =
      Color(0xFFC7EEE9); // Mint Green (Soft backgrounds/cells)
  static const Color adifAmberLightSurface = Color(0xFFFEF3C7);
  static const Color adifAmberLightText = Color(0xFF92400E);
  static const Color adifAmberDarkSurface = Color(0xFF3B2608);
  static const Color adifAmberDarkText = Color(0xFFFBBF24);
  static const Color adifPlatformLightSurface = Color(0xFFE6F4EE);
  static const Color adifPlatformLightText = Color(0xFF006338);
  static const Color adifPlatformDarkSurface = Color(0xFF153327);
  static const Color adifPlatformDarkText = Color(0xFF4CD99B);
  static const Color adifNavDarkSurface = Color(0xFF19382C);
  static const Color adifNavDarkText = Color(0xFF4CD99B);

  // Neutral surfaces for the real-time station board.
  static const Color stationLightBackground = Color(0xFFF5F7FA);
  static const Color stationDarkBackground = Color(0xFF0D1117);
  static const Color stationLightCard = Color(0xFFFFFFFF);
  static const Color stationDarkCard = Color(0xFF161E29);
  static const Color stationLightBorder = Color(0xFFD8E0E8);
  static const Color stationDarkBorder = Color(0xFF2D3A4B);

  // Light Mode Tokens
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightGlassSurface = Color(0xF2FFFFFF);
  static const Color lightCardBorder = Color(0xFFD8E0E8);
  static const Color lightInputBorder = Color(0xFFD8E0E8);
  static const Color lightNavActiveHighlight = Color(0xFFD9EFE6);
  static const Color lightNavActiveText = adifPrimary;

  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF64748B);

  // Dark Mode Tokens
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161E29);
  static const Color darkGlassSurface = Color(0xF2161E29);
  static const Color darkCardBorder = Color(0xFF2D3A4B);
  static const Color darkInputBorder = Color(0xFF3A495E);
  static const Color darkNavActiveHighlight = adifNavDarkSurface;
  static const Color darkNavActiveText = adifNavDarkText;

  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // Station Screen Backgrounds
  static const Color adifNavyBackground = Color(0xFF0F1D2E);
  static const Color adifNavySurface = Color(0xFF0F1D2E);

  // Status & Rail Signal Colors
  static const Color statusOnTime = Color(0xFF1E8E3E);
  static const Color statusDelay = Color(0xFFD97706);
  static const Color statusCancelled = Color(0xFFDC2626);
  static const Color adifGreen = adifPrimary;

  // Backward-compatible static references
  static const Color background = darkBackground;
  static const Color surface = darkSurface;
  static const Color surfaceGlass = darkGlassSurface;
  static const Color glassBorder = darkCardBorder;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textMuted = darkTextMuted;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color getBackgroundColor(BuildContext context) =>
      isDark(context) ? darkBackground : lightBackground;

  static Color getSurfaceColor(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  static Color getGlassBorder(BuildContext context) =>
      isDark(context) ? darkCardBorder : lightCardBorder;

  static Color getTextPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : lightTextPrimary;

  static Color getTextSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;

  static Color getTextMuted(BuildContext context) =>
      isDark(context) ? darkTextMuted : lightTextMuted;

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        surface: lightSurface,
        onSurface: lightTextPrimary,
        onSurfaceVariant: lightTextSecondary,
        primary: adifPrimary,
        secondary: adifTeal,
      ),
      inputDecorationTheme: InputDecorationTheme(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: lightInputBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: adifTeal, width: 1.5),
        ),
      ),
      fontFamily: '.SF Pro Text',
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        surface: darkSurface,
        onSurface: darkTextPrimary,
        onSurfaceVariant: darkTextSecondary,
        primary: adifPrimary,
        secondary: adifTeal,
      ),
      inputDecorationTheme: InputDecorationTheme(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: darkInputBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: adifMint, width: 1.5),
        ),
      ),
      fontFamily: '.SF Pro Text',
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
