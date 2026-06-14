import 'package:flutter/material.dart';
import 'colors.dart';
import 'text_styles.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: OmegaColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: OmegaColors.primary,
        secondary: OmegaColors.secondary,
        surface: OmegaColors.surfaceLight,
        error: OmegaColors.error,
      ),
      textTheme: OmegaTextStyles.textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: OmegaColors.surfaceLight,
        foregroundColor: OmegaColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: OmegaTextStyles.titleLarge.copyWith(
          color: OmegaColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: OmegaColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OmegaColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: OmegaColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: OmegaColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: OmegaColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: OmegaTextStyles.labelLarge,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: OmegaColors.divider,
        thickness: 0.5,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: OmegaColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: OmegaColors.primaryDark,
        secondary: OmegaColors.secondary,
        surface: OmegaColors.surfaceDark,
        error: OmegaColors.error,
      ),
      textTheme: OmegaTextStyles.textThemeDark,
      appBarTheme: AppBarTheme(
        backgroundColor: OmegaColors.surfaceDark,
        foregroundColor: OmegaColors.textPrimaryDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: OmegaTextStyles.titleLarge.copyWith(
          color: OmegaColors.textPrimaryDark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: OmegaColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OmegaColors.inputFillDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: OmegaColors.primaryDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: OmegaColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: OmegaColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: OmegaTextStyles.labelLarge,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: OmegaColors.dividerDark,
        thickness: 0.5,
      ),
    );
  }
}
