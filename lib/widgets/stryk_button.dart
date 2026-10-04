import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'pressable_scale.dart';

enum StrykButtonVariant { primary, secondary }

class StrykButton extends StatelessWidget {
  const StrykButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = StrykButtonVariant.primary,
    this.enabled = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final StrykButtonVariant variant;
  final bool enabled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == StrykButtonVariant.primary;
    final background = isPrimary ? AppColors.amber : Colors.transparent;
    final foreground = isPrimary ? AppColors.textOnLight : AppColors.white;
    final border = isPrimary
        ? BorderSide.none
        : const BorderSide(color: AppColors.borderSubtle);

    final canTap = enabled && !loading && onPressed != null;
    return PressableScale(
      enabled: canTap,
      onPressed: canTap ? onPressed : null,
      child: Semantics(
        button: true,
        enabled: canTap,
        label: label,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: enabled ? background : AppColors.charcoal,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.fromBorderSide(border),
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
                    : Text(
                        label,
                        style: AppTypography.button.copyWith(
                          color: enabled ? foreground : AppColors.textMuted,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
