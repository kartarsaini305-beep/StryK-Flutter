import 'package:flutter/material.dart';

import '../../app/config.dart';
import '../../core/constants/app_copy.dart';
import '../theme/app_theme.dart';

class DemoModeBadge extends StatelessWidget {
  const DemoModeBadge({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isDemoMode) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        button: onTap != null,
        label: AppCopy.demoMode,
        child: Text(
          AppCopy.demoMode,
          style: AppTypography.label.copyWith(
            fontSize: 11,
            letterSpacing: 1.4,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppTypography.subheading, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: AppTypography.body, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: AppTypography.body.copyWith(color: AppColors.error),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          child: Column(
            children: [
              Text(
                value,
                style: AppTypography.metric.copyWith(fontSize: 24),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: AppTypography.label.copyWith(fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
