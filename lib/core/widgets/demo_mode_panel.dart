import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/app_controller.dart';
import '../../widgets/stryk_button.dart';

class DemoModePanel extends ConsumerWidget {
  const DemoModePanel({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const DemoModePanel(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appControllerProvider.notifier);
    final maxH = MediaQuery.sizeOf(context).height * 0.85;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.sm,
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Demo location', style: AppTypography.subheading),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Simulate location. Enter zone, then Check In on Home. Jump to Min Stay shortcuts a completed stay. Admin → Demo Time Mode = 1s:1m.',
                style: AppTypography.body,
              ),
              const SizedBox(height: AppSpacing.lg),
              StrykButton(
                label: 'Outside Gym',
                variant: StrykButtonVariant.secondary,
                onPressed: () {
                  controller.simulateOutside();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              StrykButton(
                label: 'Enter Gym Zone',
                onPressed: () {
                  controller.simulateEnterZone();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              StrykButton(
                label: 'Leave Gym Zone',
                variant: StrykButtonVariant.secondary,
                onPressed: () {
                  controller.simulateLeaveZone();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              StrykButton(
                label: 'Jump to Min Stay',
                variant: StrykButtonVariant.secondary,
                onPressed: () {
                  controller.simulateCompleteTwentyMinutes();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              StrykButton(
                label: 'Reset Today',
                variant: StrykButtonVariant.secondary,
                onPressed: () {
                  controller.resetToday();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              StrykButton(
                label: 'Seed history',
                variant: StrykButtonVariant.secondary,
                onPressed: () {
                  controller.seedDemoHistory();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Min stay: ${ref.watch(appControllerProvider).adminConfig.minStayMinutes} min · zone ${ref.watch(appControllerProvider).adminConfig.geofenceRadiusMeters.round()} m',
                style: AppTypography.label,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
