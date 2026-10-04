import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/demo_chrome.dart';
import '../../../features/streak/models/daily_record.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/stryk_button.dart';
import '../../../widgets/stryk_logo.dart';

class DayDetailScreen extends ConsumerWidget {
  const DayDetailScreen({super.key, required this.dateKey});

  final String dateKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(appControllerProvider).records[dateKey];
    return Scaffold(
      appBar: AppBar(title: const Text('Day detail')),
      body: SafeArea(
        child: record == null
            ? const EmptyState(
                title: 'No activity',
                message: 'Nothing is stored for this day yet.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.lg,
                  AppSpacing.screenHorizontal,
                  AppSpacing.lg,
                ),
                children: [
                  const Center(child: StrykLogo(height: 24, light: true)),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    record.isCompleted
                        ? 'DAY ${record.streakAtPoint ?? '—'}'
                        : Dates.upperDay(record.calendarDate),
                    style: AppTypography.display.copyWith(fontSize: 42),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status(record),
                    style: AppTypography.label.copyWith(
                      color: record.isCompleted
                          ? AppColors.success
                          : record.kind == DayKind.sundayProtected ||
                                  record.kind == DayKind.streakSaved
                              ? AppColors.protected
                              : AppColors.textMuted,
                      letterSpacing: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _row('Date', Dates.upperDay(record.calendarDate)),
                  if (record.gymName != null) _row('Gym', record.gymName!),
                  if (record.arrivalTime != null)
                    _row('Start', Dates.time.format(record.arrivalTime!)),
                  if (record.endTime != null ||
                      (record.arrivalTime != null && record.duration != null))
                    _row(
                      'End',
                      Dates.time.format(
                        record.endTime ??
                            record.arrivalTime!.add(record.duration!),
                      ),
                    ),
                  if (record.arrivalTime != null &&
                      (record.endTime != null || record.duration != null))
                    _row(
                      'Range',
                      Dates.timeRange(
                        record.arrivalTime!,
                        record.endTime ??
                            record.arrivalTime!.add(record.duration!),
                      ),
                    ),
                  if (record.duration != null)
                    _row('Duration', Dates.friendlyDuration(record.duration!)),
                  if (record.streakAtPoint != null)
                    _row('StryK', '${record.streakAtPoint}'),
                  if (record.totalGymDaysAtThatTime != null)
                    _row('Total gym days', '${record.totalGymDaysAtThatTime}'),
                  if (record.verificationId != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _row('Verification ID', record.verificationId!),
                  ],
                  if (record.isCompleted) ...[
                    const SizedBox(height: AppSpacing.xl),
                    StrykButton(
                      label: 'Share This StryK',
                      onPressed: () =>
                          context.push(AppRoutes.shareFor(record.dateKey)),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  String _status(DailyRecord record) {
    return switch (record.kind) {
      DayKind.completed => 'STRYK SECURED',
      DayKind.sundayProtected => 'SUNDAY SAFE',
      DayKind.streakSaved => 'STREAK SAVED',
      DayKind.missed => 'MISSED',
      DayKind.none => 'NO ACTIVITY',
    };
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: AppTypography.label)),
          Expanded(child: Text(value, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}
