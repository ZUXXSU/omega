import 'package:flutter/material.dart';
import 'colors.dart';

class OmegaTextStyles {
  static const String _fontFamily = 'Inter';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: OmegaColors.textSecondary,
  );

  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge.copyWith(color: OmegaColors.textPrimary),
    displayMedium: displayMedium.copyWith(color: OmegaColors.textPrimary),
    titleLarge: titleLarge.copyWith(color: OmegaColors.textPrimary),
    titleMedium: titleMedium.copyWith(color: OmegaColors.textPrimary),
    titleSmall: titleSmall.copyWith(color: OmegaColors.textPrimary),
    bodyLarge: bodyLarge.copyWith(color: OmegaColors.textPrimary),
    bodyMedium: bodyMedium.copyWith(color: OmegaColors.textPrimary),
    bodySmall: bodySmall.copyWith(color: OmegaColors.textSecondary),
    labelLarge: labelLarge.copyWith(color: OmegaColors.textPrimary),
    labelMedium: labelMedium.copyWith(color: OmegaColors.textSecondary),
    labelSmall: labelSmall.copyWith(color: OmegaColors.textSecondary),
  );

  static TextTheme get textThemeDark => TextTheme(
    displayLarge: displayLarge.copyWith(color: OmegaColors.textPrimaryDark),
    displayMedium: displayMedium.copyWith(color: OmegaColors.textPrimaryDark),
    titleLarge: titleLarge.copyWith(color: OmegaColors.textPrimaryDark),
    titleMedium: titleMedium.copyWith(color: OmegaColors.textPrimaryDark),
    titleSmall: titleSmall.copyWith(color: OmegaColors.textPrimaryDark),
    bodyLarge: bodyLarge.copyWith(color: OmegaColors.textPrimaryDark),
    bodyMedium: bodyMedium.copyWith(color: OmegaColors.textPrimaryDark),
    bodySmall: bodySmall.copyWith(color: OmegaColors.textSecondaryDark),
    labelLarge: labelLarge.copyWith(color: OmegaColors.textPrimaryDark),
    labelMedium: labelMedium.copyWith(color: OmegaColors.textSecondaryDark),
    labelSmall: labelSmall.copyWith(color: OmegaColors.textSecondaryDark),
  );
}
