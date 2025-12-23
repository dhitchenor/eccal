import 'package:flutter/material.dart';

enum AppColorFamily { red, blue, green, yellow, purple, cyan, neutral }

class AppColorSchemes {
  // RED
  // =============================

  static const redLight = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFD32F2F),
    onPrimary: Colors.white,
    secondary: Color(0xFFF06292),
    onSecondary: Colors.white,
    tertiary: Color(0xFFD32F2F),
    onTertiary: Colors.white,
    error: Colors.red,
    onError: Colors.white,
    background: Color(0xFFFFF5F5),
    onBackground: Colors.black,
    surface: Color(0xFFFFEBEE),
    onSurface: Colors.black,
    primaryContainer: Color(0xFFFFCDD2),
    onPrimaryContainer: Color(0xFF7F0000),
    secondaryContainer: Color(0xFFF8BBD0),
    onSecondaryContainer: Color(0xFF880E4F),
    surfaceContainer: Color(0xFFFFE5E8),
    onSurfaceVariant: Colors.grey,
    outline: Colors.grey,
    scrim: Colors.black45,
  );

  static const redDark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFF6659),
    onPrimary: Color(0xFF3B0000),
    secondary: Color(0xFFF48FB1),
    onSecondary: Colors.black,
    tertiary: Color(0xFFFF6659),
    onTertiary: Colors.white,
    error: Colors.redAccent,
    onError: Colors.black,
    background: Color(0xFF2B0A0A),
    onBackground: Colors.white,
    surface: Color(0xFF3D1010),
    onSurface: Colors.white,
    primaryContainer: Color(0xFF7F0000),
    onPrimaryContainer: Color(0xFFFFCDD2),
    secondaryContainer: Color(0xFF880E4F),
    onSecondaryContainer: Color(0xFFF8BBD0),
    surfaceContainer: Color(0xFF4A1515),
    onSurfaceVariant: Colors.grey,
    outline: Colors.grey,
    scrim: Colors.black54,
  );

  // BLUE
  // =============================

  static const blueLight = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1565C0),
    onPrimary: Colors.white,
    secondary: Color(0xFF64B5F6),
    onSecondary: Colors.white,
    tertiary: Color(0xFF1565C0),
    onTertiary: Colors.white,
    error: Colors.red,
    onError: Colors.white,
    background: Color(0xFFF0F7FF),
    onBackground: Colors.black,
    surface: Color(0xFFE3F2FD),
    onSurface: Colors.black,
    primaryContainer: Color(0xFFBBDEFB),
    onPrimaryContainer: Color(0xFF0D47A1),
    secondaryContainer: Color(0xFFE3F2FD),
    onSecondaryContainer: Color(0xFF01579B),
    surfaceContainer: Color(0xFFD6EAFF),
    onSurfaceVariant: Colors.grey,
    outline: Colors.grey,
    scrim: Colors.black45,
  );

  static const blueDark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF64B5F6),
    onPrimary: Color(0xFF0D1B2A),
    secondary: Color(0xFF90CAF9),
    onSecondary: Colors.black,
    tertiary: Color(0xFF64B5F6),
    onTertiary: Colors.white,
    error: Colors.redAccent,
    onError: Colors.black,
    background: Color(0xFF0A1929),
    onBackground: Colors.white,
    surface: Color(0xFF132F4C),
    onSurface: Colors.white,
    primaryContainer: Color(0xFF0D47A1),
    onPrimaryContainer: Color(0xFFBBDEFB),
    secondaryContainer: Color(0xFF01579B),
    onSecondaryContainer: Color(0xFFE3F2FD),
    surfaceContainer: Color(0xFF1A3A52),
    onSurfaceVariant: Colors.grey,
    outline: Colors.grey,
    scrim: Colors.black54,
  );

  // GREEN
  // =============================

  static const greenLight = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2E7D32),
    onPrimary: Colors.white,
    secondary: Color(0xFF81C784),
    onSecondary: Colors.white,
    tertiary: Color(0xFF2E7D32),
    onTertiary: Colors.white,
    error: Colors.red,
    onError: Colors.white,
    background: Color(0xFFF1F8F4),
    onBackground: Colors.black,
    surface: Color(0xFFE8F5E9),
    onSurface: Colors.black,
    primaryContainer: Color(0xFFC8E6C9),
    onPrimaryContainer: Color(0xFF1B5E20),
    secondaryContainer: Color(0xFFE8F5E9),
    onSecondaryContainer: Color(0xFF2E7D32),
    surfaceContainer: Color(0xFFDBEFDC),
    onSurfaceVariant: Colors.grey,
    outline: Colors.grey,
    scrim: Colors.black45,
  );

  static const greenDark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF81C784),
    onPrimary: Color(0xFF003300),
    secondary: Color(0xFFA5D6A7),
    onSecondary: Colors.black,
    tertiary: Color(0xFF81C784),
    onTertiary: Colors.white,
    error: Colors.redAccent,
    onError: Colors.black,
    background: Color(0xFF0D1F0F),
    onBackground: Colors.white,
    surface: Color(0xFF1A2E1D),
    onSurface: Colors.white,
    primaryContainer: Color(0xFF1B5E20),
    onPrimaryContainer: Color(0xFFC8E6C9),
    secondaryContainer: Color(0xFF2E7D32),
    onSecondaryContainer: Color(0xFFE8F5E9),
    surfaceContainer: Color(0xFF243828),
    onSurfaceVariant: Colors.grey,
    outline: Colors.grey,
    scrim: Colors.black54,
  );

  // YELLOW
  // =============================

  static const yellowLight = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFFBC02D),
    onPrimary: Colors.black,
    secondary: Color(0xFFFFE082),
    onSecondary: Colors.black,
    tertiary: Color(0xFFFBC02D),
    onTertiary: Colors.black,
    error: Colors.red,
    onError: Colors.white,
    background: Color(0xFFFFFCF5),
    onBackground: Colors.black,
    surface: Color(0xFFFFF8E1),
    onSurface: Colors.black,
    primaryContainer: Color(0xFFFFF8E1),
    onPrimaryContainer: Color(0xFF8C6E00),
    secondaryContainer: Color(0xFFFFECB3),
    onSecondaryContainer: Color(0xFF7F6000),
    surfaceContainer: Color(0xFFFFF4D6),
    onSurfaceVariant: Colors.grey,
    outline: Colors.grey,
    scrim: Colors.black45,
  );

  static const yellowDark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFE082),
    onPrimary: Color(0xFF3A3000),
    secondary: Color(0xFFFFF59D),
    onSecondary: Colors.black,
    tertiary: Color(0xFFFFE082),
    onTertiary: Colors.black,
    error: Colors.redAccent,
    onError: Colors.black,
    background: Color(0xFF2B2410),
    onBackground: Colors.white,
    surface: Color(0xFF3D3318),
    onSurface: Colors.white,
    primaryContainer: Color(0xFF8C6E00),
    onPrimaryContainer: Color(0xFFFFF8E1),
    secondaryContainer: Color(0xFF7F6000),
    onSecondaryContainer: Color(0xFFFFECB3),
    surfaceContainer: Color(0xFF4A4020),
    onSurfaceVariant: Colors.grey,
    outline: Colors.grey,
    scrim: Colors.black54,
  );

  // PURPLE
  // =============================

  static const purpleLight = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF7B1FA2),
    onPrimary: Colors.white,
    secondary: Color(0xFFCE93D8),
    onSecondary: Colors.white,
    tertiary: Color(0xFF7B1FA2),
    onTertiary: Colors.white,
    error: Colors.red,
    onError: Colors.white,
    background: Color(0xFFFAF5FC),
    onBackground: Colors.black,
    surface: Color(0xFFF3E5F5),
    onSurface: Colors.black,
    primaryContainer: Color(0xFFE1BEE7),
    onPrimaryContainer: Color(0xFF4A0072),
    secondaryContainer: Color(0xFFF3E5F5),
    onSecondaryContainer: Color(0xFF6A1B9A),
    surfaceContainer: Color(0xFFEAD9F0),
    onSurfaceVariant: Colors.grey,
    outline: Colors.grey,
    scrim: Colors.black45,
  );

  static const purpleDark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFCE93D8),
    onPrimary: Color(0xFF2A0036),
    secondary: Color(0xFFE1BEE7),
    onSecondary: Colors.black,
    tertiary: Color(0xFFCE93D8),
    onTertiary: Colors.white,
    error: Colors.redAccent,
    onError: Colors.black,
    background: Color(0xFF1A0A24),
    onBackground: Colors.white,
    surface: Color(0xFF2C1535),
    onSurface: Colors.white,
    primaryContainer: Color(0xFF4A0072),
    onPrimaryContainer: Color(0xFFE1BEE7),
    secondaryContainer: Color(0xFF6A1B9A),
    onSecondaryContainer: Color(0xFFF3E5F5),
    surfaceContainer: Color(0xFF38204A),
    onSurfaceVariant: Colors.grey,
    outline: Colors.grey,
    scrim: Colors.black54,
  );

  // CYAN
  // =============================

  static const cyanLight = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0097A7),
    onPrimary: Colors.white,
    secondary: Color(0xFF80DEEA),
    onSecondary: Colors.black,
    tertiary: Color(0xFF0097A7),
    onTertiary: Colors.white,
    error: Colors.red,
    onError: Colors.white,
    background: Color(0xFFF0FEFF),
    onBackground: Colors.black,
    surface: Color(0xFFE0F7FA),
    onSurface: Colors.black,
    primaryContainer: Color(0xFFB2EBF2),
    onPrimaryContainer: Color(0xFF004D56),
    secondaryContainer: Color(0xFFE0F7FA),
    onSecondaryContainer: Color(0xFF006064),
    surfaceContainer: Color(0xFFD4F1F4),
    onSurfaceVariant: Colors.grey,
    outline: Colors.grey,
    scrim: Colors.black45,
  );

  static const cyanDark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF80DEEA),
    onPrimary: Color(0xFF00292C),
    secondary: Color(0xFFB2EBF2),
    onSecondary: Colors.black,
    tertiary: Color(0xFF80DEEA),
    onTertiary: Colors.white,
    error: Colors.redAccent,
    onError: Colors.black,
    background: Color(0xFF0A1F21),
    onBackground: Colors.white,
    surface: Color(0xFF142E30),
    onSurface: Colors.white,
    primaryContainer: Color(0xFF004D56),
    onPrimaryContainer: Color(0xFFB2EBF2),
    secondaryContainer: Color(0xFF006064),
    onSecondaryContainer: Color(0xFFE0F7FA),
    surfaceContainer: Color(0xFF1D3B3E),
    onSurfaceVariant: Colors.grey,
    outline: Colors.grey,
    scrim: Colors.black54,
  );

  // NEUTRAL
  // =============================

  static const neutralLight = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF757575),
    onPrimary: Colors.black,
    secondary: Color(0xFFF5F5F5),
    onSecondary: Colors.black,
    tertiary: Color(0xFF424242),
    onTertiary: Colors.white,
    error: Colors.red,
    onError: Colors.white,
    background: Color(0xFFFFFFFF),
    onBackground: Colors.black,
    surface: Colors.white,
    onSurface: Colors.black,
    primaryContainer: Color(0xFFF0F0F0),
    onPrimaryContainer: Colors.black,
    secondaryContainer: Color(0xFFE0E0E0),
    onSecondaryContainer: Colors.black,
    surfaceContainer: Color(0xFFF7F7F7),
    onSurfaceVariant: Colors.grey,
    outline: Colors.grey,
    scrim: Colors.black45,
  );

  static const neutralDark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF757575),
    onPrimary: Colors.white,
    secondary: Color(0xFFBDBDBD),
    onSecondary: Colors.black,
    tertiary: Color(0xFFE0E0E0),
    onTertiary: Colors.black,
    error: Colors.redAccent,
    onError: Colors.black,
    background: Color(0xFF000000),
    onBackground: Colors.white,
    surface: Color(0xFF121212),
    onSurface: Colors.white,
    primaryContainer: Color(0xFF000000),
    onPrimaryContainer: Colors.white,
    secondaryContainer: Color(0xFF424242),
    onSecondaryContainer: Colors.white,
    surfaceContainer: Color(0xFF1A1A1A),
    onSurfaceVariant: Colors.grey,
    outline: Colors.grey,
    scrim: Colors.black54,
  );

  // HELPER
  // =============================

  static ColorScheme getScheme(AppColorFamily family, bool dark) {
    switch (family) {
      case AppColorFamily.red:
        return dark ? redDark : redLight;
      case AppColorFamily.blue:
        return dark ? blueDark : blueLight;
      case AppColorFamily.green:
        return dark ? greenDark : greenLight;
      case AppColorFamily.yellow:
        return dark ? yellowDark : yellowLight;
      case AppColorFamily.purple:
        return dark ? purpleDark : purpleLight;
      case AppColorFamily.cyan:
        return dark ? cyanDark : cyanLight;
      case AppColorFamily.neutral:
        return dark ? neutralDark : neutralLight;
    }
  }
}