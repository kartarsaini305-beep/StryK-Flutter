import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/demo_chrome.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/stryk_button.dart';
import '../../../widgets/stryk_logo.dart';

class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key, required this.verificationId});

  final String verificationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final record = ref.watch(verificationServiceProvider).findById(
          app.records,
          verificationId,
        );

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
          ),
          child: record == null
              ? const EmptyState(
                  title: 'Not found',
                  message: 'This verification ID is not stored on this device yet.',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: StrykLogo(height: 28, light: true)),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'STRYK VERIFIED',
                      style: AppTypography.label.copyWith(
                        color: AppColors.success,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Day ${record.streakAtPoint ?? '—'}',
                      style: AppTypography.heading,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(Dates.upperDay(record.calendarDate), style: AppTypography.body, textAlign: TextAlign.center),
                    if (record.arrivalTime != null)
                      Text(
                        Dates.time.format(record.arrivalTime!),
                        style: AppTypography.body,
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(record.gymName ?? '', style: AppTypography.subheading, textAlign: TextAlign.center),
                    if (record.duration != null)
                      Text(
                        '${Dates.minutesLabel(record.duration!)} completed',
                        style: AppTypography.body,
                        textAlign: TextAlign.center,
                      ),
                    if (record.totalGymDaysAtThatTime != null)
                      Text(
                        '${record.totalGymDaysAtThatTime} total gym days',
                        style: AppTypography.body,
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Verification ID:\n$verificationId',
                      style: AppTypography.label,
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    StrykButton(
                      label: 'Open StryK',
                      onPressed: () => context.go(AppRoutes.home),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
