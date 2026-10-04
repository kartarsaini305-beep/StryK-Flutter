import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static const family = 'Inter';

  static TextStyle _base({
    required double size,
    required double weight,
    Color color = AppColors.textPrimary,
    double height = 1.25,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      height: height,
      color: color,
      letterSpacing: letterSpacing,
      fontVariations: [FontVariation('wght', weight)],
    );
  }

  static final display = _base(
    size: 64,
    weight: 800,
    height: 1.0,
    letterSpacing: -1.5,
  );

  static final heading = _base(size: 28, weight: 700, height: 1.15, letterSpacing: -0.4);

  static final subheading = _base(size: 18, weight: 600, height: 1.3);

  static final body = _base(size: 16, weight: 400, height: 1.45, color: AppColors.textSecondary);

  static final bodyMedium = _base(size: 16, weight: 500, height: 1.4);

  static final label = _base(
    size: 14,
    weight: 600,
    letterSpacing: 0.4,
    color: AppColors.textMuted,
  );

  static final button = _base(size: 16, weight: 600, height: 1.2, color: AppColors.textOnLight);

  static final tagline = _base(
    size: 16,
    weight: 500,
    height: 1.3,
    letterSpacing: 0.2,
    color: AppColors.textOnLight,
  );
}
