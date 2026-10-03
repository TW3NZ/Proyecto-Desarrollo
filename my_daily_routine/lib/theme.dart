import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4169E1);
  static const Color primaryDark = Color(0xFF1E2F6E);
  static const Color background = Color(0xFFF5F7FF);
  static const Color fieldFill = Color(0xFFF8FAFF);
  static const Color fieldBorder = Color(0xFFD8E3FF);
  static const Color divider = Color(0xFFE2E8F1);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textHint = Color(0xFF8AA0C7);
  static const Color textMuted = Color(0xFF64748B);
}

class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primary, Color(0xFF2F80ED)],
  );

  static const LinearGradient logo = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5A7CFF), Color(0xFF2D5BFF)],
  );

  static const LinearGradient bottomBar = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2E5CFF), Color(0xFF1C3E8D)],
  );
}

class AppRadius {
  AppRadius._();

  static const double button = 16;
  static const double field = 14;
  static const double logo = 20;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      );
}
