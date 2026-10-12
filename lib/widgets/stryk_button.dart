import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'pressable_scale.dart';

enum StrykButtonVariant { primary, secondary, danger, ghost }

class StrykButton extends StatelessWidget {
  const StrykButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = StrykButtonVariant.primary,
    this.enabled = true,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final StrykButtonVariant variant;
  final bool enabled;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case StrykButtonVariant.primary:
        background = AppColors.amber;
        foreground = AppColors.textOnLight;
      case StrykButtonVariant.secondary:
        background = AppColors.charcoal;
        foreground = AppColors.white;
        border = const BorderSide(color: AppColors.borderStrong);
      case StrykButtonVariant.danger:
        background = AppColors.danger;
        foreground = AppColors.white;
      case StrykButtonVariant.ghost:
        background = Colors.transparent;
        foreground = AppColors.amber;
    }

    final canTap = enabled && !loading && onPressed != null;
    return PressableScale(
      enabled: canTap,
      scale: 0.97,
      onPressed: canTap ? onPressed : null,
      child: Semantics(
        button: true,
        enabled: canTap,
        label: label,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: enabled ? background : AppColors.charcoal.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.fromBorderSide(border),
              boxShadow: variant == StrykButtonVariant.primary && enabled
                  ? const [
                      BoxShadow(
                        color: AppColors.amberGlow,
                        blurRadius: 18,
                        offset: Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Center(
                child: loading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 18, color: enabled ? foreground : AppColors.textMuted),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                label,
                                maxLines: 1,
                                style: AppTypography.button.copyWith(
                                  color: enabled ? foreground : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
