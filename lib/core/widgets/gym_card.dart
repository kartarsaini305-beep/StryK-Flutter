import 'package:flutter/material.dart';

import '../../features/gyms/models/gym.dart';
import '../theme/app_theme.dart';
import '../../widgets/pressable_scale.dart';

class GymCard extends StatelessWidget {
  const GymCard({
    super.key,
    required this.gym,
    required this.distanceLabel,
    required this.selected,
    required this.onTap,
  });

  final Gym gym;
  final String distanceLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onPressed: onTap,
      child: Semantics(
        button: true,
        selected: selected,
        label: '${gym.name}, $distanceLabel',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.amber : AppColors.borderSubtle,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                GymAvatar(label: gym.placeholderLabel),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(gym.name, style: AppTypography.subheading),
                      const SizedBox(height: 4),
                      Text(gym.address, style: AppTypography.body),
                    ],
                  ),
                ),
                Text(
                  distanceLabel,
                  style: AppTypography.label.copyWith(color: AppColors.amber),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GymAvatar extends StatelessWidget {
  const GymAvatar({super.key, required this.label, this.size = 48});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.subheading.copyWith(color: AppColors.amber),
          ),
        ),
      ),
    );
  }
}
