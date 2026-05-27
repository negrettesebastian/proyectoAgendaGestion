import 'package:flutter/material.dart';

class AppColors {
  // Auth pages (dark)
  static const navy = Color(0xFF0B1535);
  static const navyMid = Color(0xFF0D1B3E);
  static const navyLight = Color(0xFF1A2550);
  static const cyan = Color(0xFF00C6FF);
  static const blue = Color(0xFF1A56FF);
  static const blueLight = Color(0xFF4C7FFF);

  // Glass
  static const glassBackground = Color(0x1AFFFFFF);
  static const glassBorder = Color(0x33FFFFFF);

  // Text auth
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xAAFFFFFF);
  static const textHint = Color(0x66FFFFFF);

  // Dashboard (light)
  static const background = Color(0xFFF0F4FF);
  static const cardBg = Colors.white;
  static const calendarBg = Color(0xFF1A2540);
  static const textDark = Color(0xFF0B1535);
  static const textMid = Color(0xFF4A5568);
  static const textLight = Color(0xFF8A9BC1);

  // Estados
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const purple = Color(0xFF8B5CF6);
  static const error = Color(0xFFFF6B6B);

  static Color priority(int index) {
    const colors = [success, danger, warning, blue, purple];
    return colors[index % colors.length];
  }
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.blue,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.navyMid,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      );
}
