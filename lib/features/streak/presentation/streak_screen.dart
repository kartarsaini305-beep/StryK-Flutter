import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/demo_chrome.dart';
import '../../../core/widgets/history_tile.dart';
import '../../../core/widgets/monthly_calendar.dart';
import '../../../features/streak/services/history_query.dart';
import '../../../providers/app_controller.dart';

class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final streak = app.streak;
    final history = HistoryQuery.newestFirst(app.records);

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.lg,
                AppSpacing.screenHorizontal,
                AppSpacing.sm,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My StryK', style: AppTypography.label.copyWith(letterSpacing: 1.6)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${streak.current} DAYS',
                      style: AppTypography.display.copyWith(fontSize: 48),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        StatCard(label: 'Current', value: '${streak.current}'),
                        const SizedBox(width: 10),
                        StatCard(label: 'Best', value: '${streak.best}'),
                        const SizedBox(width: 10),
                        StatCard(label: 'Gym days', value: '${streak.totalGymDays}'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Monthly activity', style: AppTypography.subheading),
                    const SizedBox(height: AppSpacing.md),
                    MonthlyCalendar(
                      records: app.records,
                      minStay: app.minStay,
                      onDayTap: (day) {
                        final key = Dates.key(day);
                        context.push(AppRoutes.dayFor(key));
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('History', style: AppTypography.subheading),
                    const SizedBox(height: AppSpacing.sm),
                    if (history.isEmpty)
                      EmptyState(
                        title: 'Your first StryK is waiting.',
                        message:
                            'Show up for ${app.minStay.inMinutes} continuous minutes to start your history.',
                      ),
                  ],
                ),
              ),
            ),
            if (history.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  0,
                  AppSpacing.screenHorizontal,
                  AppSpacing.lg,
                ),
                sliver: SliverList.separated(
                  itemCount: history.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final record = history[index];
                    return HistoryTile(
                      record: record,
                      onTap: () => context.push(AppRoutes.dayFor(record.dateKey)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
