import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';

/// Text styles aligned with remove-companion Tailwind scale.
abstract final class AppTypography {
  static const String _font = 'Roboto';

  static const TextStyle display = TextStyle(
    fontFamily: _font,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.foreground,
    height: 1.2,
  );

  static const TextStyle title = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.foreground,
  );

  static const TextStyle section = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.foreground,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.foreground,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.mutedForeground,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _font,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: _font,
    fontSize: 9,
    fontWeight: FontWeight.w600,
    color: AppColors.muted,
  );

  static const TextStyle hint = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Color(0xFFAAAAAA),
  );

  static const TextStyle link = TextStyle(
    fontFamily: _font,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static TextTheme get textTheme => const TextTheme(
        displaySmall: display,
        titleMedium: title,
        titleSmall: section,
        bodyMedium: body,
        bodySmall: bodySm,
        labelSmall: micro,
      );
}
