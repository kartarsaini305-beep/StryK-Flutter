import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'pressable_scale.dart';

class StrykCard extends StatelessWidget {
  const StrykCard({
    super.key,
    required this.child,
    this.padding,
    this.glow = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool glow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            glow ? const Color(0xFF1A160C) : AppColors.backgroundElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: glow
              ? AppColors.amber.withValues(alpha: 0.4)
              : AppColors.borderSubtle,
        ),
        boxShadow: glow
            ? const [
                BoxShadow(
                  color: AppColors.amberGlow,
                  blurRadius: 28,
                  offset: Offset(0, 10),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );

    if (onTap == null) return card;
    return PressableScale(onPressed: onTap, scale: 0.985, child: card);
  }
}
