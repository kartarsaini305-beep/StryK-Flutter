import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    final colorScheme = const ColorScheme.dark(
      primary: AppColors.amber,
      onPrimary: AppColors.textOnLight,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      secondary: AppColors.charcoal,
      onSecondary: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.white,
      outline: AppColors.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTypography.family,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      canvasColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        // Never collapse actions into a ⋮ overflow menu.
        actionsIconTheme: const IconThemeData(color: AppColors.textPrimary),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTypography.subheading,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        toolbarHeight: 56,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.backgroundElevated,
        indicatorColor: AppColors.amber.withValues(alpha: 0.14),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.label.copyWith(
            fontSize: 10,
            letterSpacing: 0.4,
            color: selected ? AppColors.amber : AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.amber : AppColors.textMuted,
            size: 22,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      dividerColor: AppColors.borderSubtle,
      textTheme: TextTheme(
        displayLarge: AppTypography.display,
        headlineLarge: AppTypography.heading,
        titleMedium: AppTypography.subheading,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.bodyMedium,
        labelLarge: AppTypography.button,
      ),
    );
  }
}
