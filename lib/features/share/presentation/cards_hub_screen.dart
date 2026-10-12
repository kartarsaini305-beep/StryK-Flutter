import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/demo_chrome.dart';
import '../../../core/widgets/share_card.dart';
import '../../../features/share/models/share_payload.dart';
import '../../../features/share/services/monthly_leaderboard_service.dart';
import '../../../features/streak/services/history_query.dart';
import '../../../providers/app_controller.dart';
import '../../../providers/app_state.dart';
import '../../../widgets/stryk_button.dart';
import '../../../widgets/stryk_card.dart';
import '../../../widgets/stryk_logo.dart';

class CardsHubScreen extends ConsumerWidget {
  const CardsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final todayKey = Dates.key(DateTime.now());
    final today = app.records[todayKey];
    final completed = HistoryQuery.newestFirst(app.records)
        .where((r) => r.isCompleted)
        .toList();
    final featured = today?.isCompleted == true
        ? today!
        : (completed.isEmpty ? null : completed.first);

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
                AppSpacing.lg,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      Text('Cards', style: AppTypography.heading),
                      const Spacer(),
                      const StrykLogo(height: 22, light: true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share your verified gym streak.',
                    style: AppTypography.body,
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
                          label: 'Monthly',
                          variant: StrykButtonVariant.ghost,
                          onPressed: () =>
                              context.push(AppRoutes.monthlyResult),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (featured == null)
                    const EmptyState(
                      title: 'No cards yet',
                      message:
                          'Complete a session and check out to unlock Get Your Card.',
                    )
                  else ...[
                    StrykCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            featured.dateKey == todayKey
                                ? "Today's card"
                                : 'Latest StryK',
                            style: AppTypography.label,
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 360),
                              child: FutureBuilder<int?>(
                                future: () async {
                                  final user = app.user;
                                  final gym = app.effectiveGym?.name ?? '';
                                  if (user == null || gym.isEmpty) return null;
                                  final month =
                                      MonthlyLeaderboardService.monthKey();
                                  final days = MonthlyLeaderboardService
                                      .verifiedDaysForMonth(
                                    app.records,
                                    month,
                                  );
                                  return MonthlyLeaderboardService()
                                      .gymRankForUser(
                                    userId: user.id.isEmpty
                                        ? 'local-user'
                                        : user.id,
                                    gymName: gym,
                                    month: month,
                                    localVerifiedDays: days,
                                    displayName: user.name,
                                  );
                                }(),
                                builder: (context, snap) {
                                  return ShareCardCanvas(
                                    payload: SharePayload.fromRecord(
                                      featured,
                                      gymRank: snap.data,
                                    ),
                                    style: ShareCardStyleX.parse(
                                      featured.cardStyle ??
                                          app.adminConfig.defaultCardStyle,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          StrykButton(
                            label: featured.dateKey == todayKey &&
                                    app.todayStatus() == TodayStatus.completed
                                ? 'Get Your Card'
                                : 'Choose style',
                            onPressed: () =>
                                context.push(AppRoutes.shareFor(featured.dateKey)),
                          ),
                        ],
                      ),
                    ),
                    if (completed.length > 1) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Text('ALL SESSIONS', style: AppTypography.label),
                      const SizedBox(height: AppSpacing.sm),
                      for (final record in completed.take(12))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'STRYK ${record.streakAtPoint ?? '—'}',
                              style: AppTypography.bodyMedium,
                            ),
                            subtitle: Text(
                              '${Dates.dayStampShort.format(record.calendarDate)} · ${record.duration != null ? Dates.friendlyDuration(record.duration!) : '—'}',
                              style: AppTypography.label,
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: AppColors.textMuted,
                            ),
                            onTap: () =>
                                context.push(AppRoutes.shareFor(record.dateKey)),
                          ),
                        ),
                    ],
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
