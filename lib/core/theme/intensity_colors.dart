import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Duration-based activity / timer colors.
abstract final class IntensityColors {
  static const under10 = Color(0xFF8B1E1E);
  static const midTransition = Color(0xFFC45C3A);
  static const light = Color(0xFFB8D4A8);
  static const medium = Color(0xFF6FAE7B);
  static const dark = Color(0xFF2F6B45);

  /// Smooth timer meter color from elapsed minutes.
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

  /// Calendar cell intensity for a completed session duration.
  /// Below [minStay] is treated as incomplete / invalid activity.
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
