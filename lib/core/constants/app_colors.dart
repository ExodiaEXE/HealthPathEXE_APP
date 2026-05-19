import 'package:flutter/material.dart';

/// Design tokens ported from remove-companion `globals.css`.
abstract final class AppColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color foreground = Color(0xFF1A1A1A);
  static const Color primary = Color(0xFF3D7A2E);
  static const Color primaryDark = Color(0xFF2E6420);
  static const Color primaryLight = Color(0xFF5B9F4A);
  static const Color accent = Color(0xFF4A90C8);
  static const Color coral = Color(0xFFD4855A);
  static const Color destructive = Color(0xFFD45A5A);
  static const Color border = Color(0xFFEEEEEE);
  static const Color muted = Color(0xFF888888);
  static const Color mutedForeground = Color(0xFF555555);
  static const Color cardShadow = Color(0x14000000);
  static const Color darkGreen = Color(0xFF2E5B22);
  static const Color surfaceMuted = Color(0xFFF8F8F8);
  static const Color streakOrange = Color(0xFFFFA040);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary],
  );

  static const LinearGradient authBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3D7A2E),
      Color(0xFF4A90C8),
      Color(0xFFF5EDE4),
      Color(0xFF3D7A2E),
      Color(0xFFD4855A),
    ],
  );
}
