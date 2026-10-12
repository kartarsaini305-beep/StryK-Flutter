import 'package:flutter/material.dart';

import 'app_colors.dart';

/// High-contrast duration intensity using StryK brand palette.
abstract final class IntensityColors {
  /// Under 10m — darkest red-side.
  static const under10 = Color(0xFF5A1414);

  /// 10–20m bridge toward amber.
  static const midTransition = Color(0xFFC47A3A);

  /// 20–30m — clearly light.
  static const light = Color(0xFFF0E0C0);

  /// 30–50m — clearly medium (brand amber).
  static const medium = Color(0xFFF5BD6E);

  /// 50+m — clearly darkest green-compatible.
  static const dark = Color(0xFF1E4D30);

  static Color timerColor(Duration elapsed) {
    final m = elapsed.inSeconds / 60.0;
    if (m <= 0) return under10;
    if (m < 10) {
      return Color.lerp(under10, midTransition, (m / 10).clamp(0, 1))!;
    }
    if (m < 20) {
      return Color.lerp(midTransition, light, ((m - 10) / 10).clamp(0, 1))!;
    }
    if (m < 30) {
      return Color.lerp(light, medium, ((m - 20) / 10).clamp(0, 1))!;
    }
    if (m < 50) {
      return Color.lerp(medium, dark, ((m - 30) / 20).clamp(0, 1))!;
    }
    return dark;
  }

  static Color calendarIntensity(
    Duration? duration, {
    Duration minStay = const Duration(minutes: 20),
  }) {
    if (duration == null) return AppColors.charcoal;
    final minutes = duration.inMinutes;
    if (minutes < minStay.inMinutes) return AppColors.charcoalDeep;
    if (minutes < 30) return light;
    if (minutes < 50) return medium;
    return dark;
  }
}
