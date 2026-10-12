import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/demo_chrome.dart';
import '../../../core/widgets/history_tile.dart';
import '../../../core/widgets/monthly_calendar.dart';
import '../../../features/streak/services/history_query.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/stryk_button.dart';
import '../../../widgets/stryk_card.dart';
import '../../../widgets/stryk_logo.dart';

class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final streak = app.streak;
    final history = HistoryQuery.newestFirst(app.records);
    final completed = history.where((r) => r.isCompleted && r.duration != null);
    final avgMinutes = completed.isEmpty
        ? 0
        : (completed
                    .map((r) => r.duration!.inMinutes)
                    .reduce((a, b) => a + b) /
                completed.length)
            .round();
    final monthLabel = DateFormat('MMMM yyyy').format(DateTime.now());

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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('My Activity', style: AppTypography.heading),
                              const SizedBox(height: 4),
                              Text(
                                monthLabel,
                                style: AppTypography.body.copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const StrykLogo(height: 22, light: true),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        StatCard(
                          label: 'Sessions',
                          value: '${streak.totalGymDays}',
                        ),
                        const SizedBox(width: 10),
                        StatCard(
                          label: 'Avg',
                          value: avgMinutes == 0 ? '—' : '${avgMinutes}m',
                        ),
                        const SizedBox(width: 10),
                        StatCard(label: 'Best', value: '${streak.best}'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    StrykCard(
                      glow: streak.current > 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: AppColors.amber,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CURRENT STREAK',
                                  style: AppTypography.label.copyWith(
                                    fontSize: 10,
                                    color: AppColors.amber,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${streak.current} days',
                                    style: AppTypography.metric,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            color: AppColors.divider,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'BEST',
                                style: AppTypography.label.copyWith(fontSize: 10),
                              ),
                              Text(
                                '${streak.best}',
                                style: AppTypography.subheading,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: StrykButton(
                            label: 'Leaderboard',
                            variant: StrykButtonVariant.secondary,
                            onPressed: () =>
                                context.push(AppRoutes.leaderboard),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StrykButton(
                            label: 'Monthly result',
                            variant: StrykButtonVariant.ghost,
                            onPressed: () =>
                                context.push(AppRoutes.monthlyResult),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('MONTHLY ACTIVITY', style: AppTypography.label),
                    const SizedBox(height: AppSpacing.sm),
                    StrykCard(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
                      child: MonthlyCalendar(
                        records: app.records,
                        minStay: app.minStay,
                        onDayTap: (day) {
                          final key = Dates.key(day);
                          context.push(AppRoutes.dayFor(key));
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('RECENT SESSIONS', style: AppTypography.label),
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
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final record = history[index];
                    return HistoryTile(
                      record: record,
                      onTap: () =>
                          context.push(AppRoutes.dayFor(record.dateKey)),
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
