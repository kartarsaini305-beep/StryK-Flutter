import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class StrykCard extends StatelessWidget {
  const StrykCard({
    super.key,
    required this.child,
    this.padding,
    this.glow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: glow
            ? const [
                BoxShadow(
                  color: AppColors.amberGlow,
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}
