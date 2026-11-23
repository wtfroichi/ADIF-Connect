import 'package:flutter/material.dart';

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

  // Light Mode Tokens
  static const Color lightBackground = Color(0xFFF7F5F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightGlassSurface = Color(0xF2FFFFFF);
  static const Color lightCardBorder =
      Color(0x59680A51); // #680A51 at 0.35 opacity
  static const Color lightNavActiveHighlight = Color(0xFFEFE4EE);
  static const Color lightNavActiveText = renfePrimary;

  static const Color lightTextPrimary =
      Color(0xFF141218); // Dark ink for crisp contrast
  static const Color lightTextSecondary =
      Color(0xFF49454E); // Accessible medium ink
  static const Color lightTextMuted = Color(0xFF79747E);

  // Dark Mode Tokens
  static const Color darkBackground = Color(0xFF121014);
  static const Color darkSurface = Color(0xFF1C1920);
  static const Color darkGlassSurface = Color(0xE61C1920);
  static const Color darkCardBorder =
      Color(0x738E136F); // #8E136F at 0.45 opacity
  static const Color darkNavActiveHighlight = Color(0xFF2D1E2A);
  static const Color darkNavActiveText = Color(0xFFE20074);

  static const Color darkTextPrimary =
      Color(0xFFF5F3F7); // High contrast light text
  static const Color darkTextSecondary = Color(0xFFCAC4CF);
  static const Color darkTextMuted = Color(0xFF948F99);

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
        primary: adifTeal,
        secondary: adifPrimary,
      ),
      fontFamily: '.SF Pro Text',
      appBarTheme: const AppBarTheme(
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
        primary: adifTeal,
        secondary: adifPrimary,
      ),
      fontFamily: '.SF Pro Text',
      appBarTheme: const AppBarTheme(
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
