import 'package:flutter/material.dart';

import 'app_colors.dart';
import '../../services/appearance_controller.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark({
    CircadianPhase period = CircadianPhase.night,
    DarkAppearance mode = DarkAppearance.soft,
  }) {
    final textTheme = ThemeData.dark().textTheme;
    final palette = _palette(period, mode);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme.dark(
        primary: palette.accent,
        secondary: AppColors.mintSoft,
        surface: palette.surface,
        error: AppColors.danger,
      ),
      textTheme: textTheme.apply(
        bodyColor: AppColors.frost,
        displayColor: AppColors.frost,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.frost,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.elevated,
        indicatorColor: AppColors.mintDim,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.mint : AppColors.muted,
          );
        }),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.navyCard,
        contentTextStyle: TextStyle(color: AppColors.frost),
      ),
      dividerColor: palette.border,
    );
  }

  static ({Color background, Color surface, Color elevated, Color accent, Color border})
      _palette(CircadianPhase period, DarkAppearance mode) {
    if (mode == DarkAppearance.trueBlack) {
      return (
        background: const Color(0xFF000000),
        surface: const Color(0xFF101212),
        elevated: const Color(0xFF181B1A),
        accent: AppColors.mintSoft,
        border: const Color(0x2600BFA5),
      );
    }
    return switch (period) {
      CircadianPhase.dawn => (
          background: const Color(0xFF172333),
          surface: const Color(0xFF203247),
          elevated: const Color(0xFF293B50),
          accent: const Color(0xFFFFC58B),
          border: const Color(0x33FFC58B),
        ),
      CircadianPhase.day => (
          background: const Color(0xFF101D2B),
          surface: const Color(0xFF1B2B3C),
          elevated: const Color(0xFF26384A),
          accent: AppColors.mint,
          border: const Color(0x3300E676),
        ),
      CircadianPhase.sunset => (
          background: const Color(0xFF211E25),
          surface: const Color(0xFF30262A),
          elevated: const Color(0xFF3C3030),
          accent: const Color(0xFFFFA879),
          border: const Color(0x33FFA879),
        ),
      CircadianPhase.night => (
          background: AppColors.navy,
          surface: AppColors.navyCard,
          elevated: AppColors.navyElevated,
          accent: AppColors.mint,
          border: const Color(0x3300E676),
        ),
    };
  }
}
