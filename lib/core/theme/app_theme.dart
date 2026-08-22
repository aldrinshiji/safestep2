import 'package:flutter/material.dart';

class SafeStepThemeColors {
  final Color background;
  final Color cardBg;
  final Color cardBorder;
  final Color primaryRed;
  final Color accentPink;
  final Color accentPurple;
  final Color accentCyan;
  final Color safeGreen;
  final Color textPrimary;
  final Color textSecondary;
  final Color navBg;

  const SafeStepThemeColors({
    required this.background,
    required this.cardBg,
    required this.cardBorder,
    required this.primaryRed,
    required this.accentPink,
    required this.accentPurple,
    required this.accentCyan,
    required this.safeGreen,
    required this.textPrimary,
    required this.textSecondary,
    required this.navBg,
  });
}

class AppTheme {
  // --- FEATURED THEME PALETTES ---

  // 1. Cyber Dark (Exact screenshot theme)
  static const SafeStepThemeColors cyberDarkColors = SafeStepThemeColors(
    background: Color(0xFF070B14),
    cardBg: Color(0xFF0F172A),
    cardBorder: Color(0xFF1E293B),
    primaryRed: Color(0xFFFF2A55),
    accentPink: Color(0xFFFF4081),
    accentPurple: Color(0xFF9C27B0),
    accentCyan: Color(0xFF00E5FF),
    safeGreen: Color(0xFF00E676),
    textPrimary: Colors.white,
    textSecondary: Color(0xFF94A3B8),
    navBg: Color(0xFF0A0F1D),
  );

  // 2. Midnight Sapphire
  static const SafeStepThemeColors midnightBlueColors = SafeStepThemeColors(
    background: Color(0xFF060B18),
    cardBg: Color(0xFF0E1A33),
    cardBorder: Color(0xFF1D2D50),
    primaryRed: Color(0xFFFF2A55),
    accentPink: Color(0xFF00E5FF),
    accentPurple: Color(0xFF7C4DFF),
    accentCyan: Color(0xFF00B0FF),
    safeGreen: Color(0xFF00E676),
    textPrimary: Colors.white,
    textSecondary: Color(0xFF8DA4C4),
    navBg: Color(0xFF091124),
  );

  // 3. Sunset Crimson
  static const SafeStepThemeColors sunsetCrimsonColors = SafeStepThemeColors(
    background: Color(0xFF12070B),
    cardBg: Color(0xFF1F0D15),
    cardBorder: Color(0xFF381524),
    primaryRed: Color(0xFFFF1744),
    accentPink: Color(0xFFFF5252),
    accentPurple: Color(0xFFE040FB),
    accentCyan: Color(0xFFFFAB40),
    safeGreen: Color(0xFF00E676),
    textPrimary: Colors.white,
    textSecondary: Color(0xFFC48D9E),
    navBg: Color(0xFF160A0F),
  );

  // 4. Light Modern
  static const SafeStepThemeColors lightModernColors = SafeStepThemeColors(
    background: Color(0xFFF4F6FB),
    cardBg: Colors.white,
    cardBorder: Color(0xFFE2E8F0),
    primaryRed: Color(0xFFE53935),
    accentPink: Color(0xFFF43F5E),
    accentPurple: Color(0xFF8B5CF6),
    accentCyan: Color(0xFF06B6D4),
    safeGreen: Color(0xFF10B981),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    navBg: Colors.white,
  );

  static SafeStepThemeColors getColors(String preset) {
    switch (preset) {
      case 'midnight_blue':
        return midnightBlueColors;
      case 'sunset_crimson':
        return sunsetCrimsonColors;
      case 'light_modern':
        return lightModernColors;
      case 'cyber_dark':
      default:
        return cyberDarkColors;
    }
  }

  // Backward compatible color accessors
  static const Color primaryRed = Color(0xFFFF2A55);
  static const Color primaryOrange = Color(0xFFFF9800);
  static const Color accentRed = Color(0xFFFF1744);
  static const Color darkBackground = Color(0xFF070B14);
  static const Color darkCard = Color(0xFF0F172A);

  static ThemeData getThemeByPreset(String preset, {bool isDark = true}) {
    final colors = getColors(preset);
    final brightness = isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primaryRed,
        primary: colors.primaryRed,
        secondary: colors.accentPink,
        surface: colors.cardBg,
        brightness: brightness,
      ),
      cardTheme: CardTheme(
        color: colors.cardBg,
        elevation: isDark ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.cardBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.textPrimary),
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static ThemeData lightTheme = getThemeByPreset('light_modern', isDark: false);
  static ThemeData darkTheme = getThemeByPreset('cyber_dark', isDark: true);
}
