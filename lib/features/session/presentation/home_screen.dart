import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/greeting.dart';
import '../../../core/widgets/animated_check.dart';
import '../../../core/widgets/demo_chrome.dart';
import '../../../core/widgets/demo_mode_panel.dart';
import '../../../core/widgets/session_timer.dart';
import '../../../core/widgets/weekly_strip.dart';
import '../../../providers/app_controller.dart';
import '../../../providers/app_state.dart';
import '../../../widgets/stryk_button.dart';
import '../../../widgets/stryk_card.dart';
import '../../../widgets/stryk_logo.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final name = app.user?.name.trim().split(' ').first ?? '';
    final greeting = Greeting.of(DateTime.now());

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.sm,
                AppSpacing.screenHorizontal,
                AppSpacing.lg,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Menu',
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: const Icon(Icons.menu_rounded),
                      ),
                      const Expanded(
                        child: Center(child: StrykLogo(height: 22, light: true)),
                      ),
                      IconButton(
                        tooltip: 'Notifications',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.charcoal,
                              content: Text(
                                app.settings.arrivalNudges
                                    ? 'Arrival nudges are on.'
                                    : 'Arrival nudges are off.',
                                style: AppTypography.bodyMedium,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.notifications_none_rounded),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: DemoModeBadge(onTap: () => DemoModePanel.show(context)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (app.adminConfig.announcement.isNotEmpty) ...[
                    StrykCard(
                      child: Text(
                        app.adminConfig.announcement,
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Text(
                    name.isEmpty ? greeting : '$greeting, $name',
                    style: AppTypography.heading.copyWith(fontSize: 26),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Hero(app: app),
                  const SizedBox(height: AppSpacing.lg),
                  const _TodaysStryk(),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Active gym', style: AppTypography.label.copyWith(letterSpacing: 1.2)),
                  const SizedBox(height: AppSpacing.sm),
                  _ActiveGym(app: app),
                  const SizedBox(height: AppSpacing.lg),
                  Text('This week', style: AppTypography.label.copyWith(letterSpacing: 1.2)),
                  const SizedBox(height: AppSpacing.sm),
                  WeeklyStrip(
                    records: app.records,
                    onDayTap: (day) {
                      final key = Dates.key(day);
                      if (app.records[key] != null) {
                        context.push(AppRoutes.dayFor(key));
                      }
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    return StrykCard(
      glow: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current streak', style: AppTypography.label.copyWith(letterSpacing: 1.4)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.local_fire_department, color: AppColors.amber, size: 32),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: StreakNumber(
                    value: app.streak.current,
                    style: AppTypography.display.copyWith(fontSize: 56),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('days', style: AppTypography.subheading),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _mini('Best streak', '${app.streak.best}'),
              const SizedBox(width: 12),
              _mini('Total gym days', '${app.streak.totalGymDays}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTypography.heading.copyWith(fontSize: 22)),
          Text(label, style: AppTypography.label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ActiveGym extends StatelessWidget {
  const _ActiveGym({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final gym = app.gym;
    if (gym == null) {
      return const EmptyState(
        title: 'Choose your gym',
        message: 'Select one gym so StryK can detect when you show up.',
      );
    }
    final radius = app.geofenceRadiusMeters.round();
    final status = app.isInside ? 'Inside ${radius}m zone' : 'Outside range';
    return StrykCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gym.name,
                  style: AppTypography.subheading,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  gym.address,
                  style: AppTypography.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  status,
                  style: AppTypography.label.copyWith(
                    color: app.isInside ? AppColors.success : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            app.isInside ? Icons.location_on : Icons.location_on_outlined,
            color: app.isInside ? AppColors.amber : AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _TodaysStryk extends ConsumerWidget {
  const _TodaysStryk();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    var status = app.todayStatus();
    if (status == TodayStatus.gymDetected ||
        status == TodayStatus.tracking ||
        status == TodayStatus.secured) {
      ref.watch(tickerProvider);
      status = app.todayStatus();
    }
    final todayKey = Dates.key(DateTime.now());
    final radius = app.geofenceRadiusMeters.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's StryK", style: AppTypography.label.copyWith(letterSpacing: 1.2)),
        const SizedBox(height: AppSpacing.sm),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: StrykCard(
            key: ValueKey(status),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: switch (status) {
              TodayStatus.notStarted => _NotStarted(
                  minStayMinutes: app.minStay.inMinutes,
                  radiusMeters: radius,
                  onCheck: () {
                    if (!app.isInside) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.charcoal,
                            content: Text(
                              "StryK couldn't detect your gym.",
                              style: AppTypography.bodyMedium,
                            ),
                          ),
                        );
                    }
                    DemoModePanel.show(context);
                  },
                ),
              TodayStatus.gymDetected => _Detected(
                  minStayMinutes: app.minStay.inMinutes,
                ),
              TodayStatus.tracking => _Tracking(radiusMeters: radius),
              TodayStatus.secured => _Secured(
                  radiusMeters: radius,
                  onCheckout: () =>
                      ref.read(appControllerProvider.notifier).checkoutSession(),
                ),
              TodayStatus.interrupted => _Interrupted(
                  radiusMeters: radius,
                  onRetry: () =>
                      ref.read(appControllerProvider.notifier).retryAfterInterrupt(),
                ),
              TodayStatus.completed => _Completed(
                  day: app.streak.current,
                  duration: app.todayRecord()?.duration ?? app.elapsed(),
                  start: app.todayRecord()?.arrivalTime ?? app.session?.startTime,
                  end: app.todayRecord()?.endTime ?? app.session?.endTime,
                  onShare: () => context.push(AppRoutes.shareFor(todayKey)),
                ),
            },
          ),
        ),
      ],
    );
  }
}

class _NotStarted extends StatelessWidget {
  const _NotStarted({
    required this.onCheck,
    required this.minStayMinutes,
    required this.radiusMeters,
  });

  final VoidCallback onCheck;
  final int minStayMinutes;
  final int radiusMeters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Ready to show up?', style: AppTypography.subheading),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Stay $minStayMinutes continuous minutes inside ${radiusMeters}m to secure today.',
          style: AppTypography.body,
        ),
        const SizedBox(height: AppSpacing.lg),
        StrykButton(label: 'Check gym status', onPressed: onCheck),
      ],
    );
  }
}

class _Detected extends StatelessWidget {
  const _Detected({required this.minStayMinutes});

  final int minStayMinutes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const PulseDot(),
            const SizedBox(width: 8),
            Expanded(child: Text("You're in.", style: AppTypography.subheading)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Stay in range for $minStayMinutes minutes.',
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Tracking extends StatelessWidget {
  const _Tracking({required this.radiusMeters});

  final int radiusMeters;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const PulseDot(),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Stay in range', style: AppTypography.subheading),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const SessionTimer(),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Leave the ${radiusMeters}m zone and today’s session will reset.',
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Secured extends StatelessWidget {
  const _Secured({
    required this.radiusMeters,
    required this.onCheckout,
  });

  final int radiusMeters;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const PulseDot(),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Session valid', style: AppTypography.subheading),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const SessionTimer(),
        const SizedBox(height: AppSpacing.md),
        // Non-clickable status — card unlocks only after checkout.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
          ),
          child: Text(
            'Streak secured. Check out to get your card.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.success),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Timer keeps running. Check out when you leave.',
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Leaving the ${radiusMeters}m zone also checks you out.',
          style: AppTypography.label,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        StrykButton(label: 'Check out', onPressed: onCheckout),
      ],
    );
  }
}

class _Interrupted extends StatelessWidget {
  const _Interrupted({
    required this.onRetry,
    required this.radiusMeters,
  });

  final VoidCallback onRetry;
  final int radiusMeters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('You left the ${radiusMeters}m range.', style: AppTypography.subheading),
        const SizedBox(height: AppSpacing.sm),
        Text(
          "Your StryK wasn't secured this time. Return to start a new StryK.",
          style: AppTypography.body,
        ),
        const SizedBox(height: AppSpacing.lg),
        StrykButton(label: 'Try again', onPressed: onRetry),
      ],
    );
  }
}

class _Completed extends StatelessWidget {
  const _Completed({
    required this.day,
    required this.duration,
    required this.onShare,
    this.start,
    this.end,
  });

  final int day;
  final Duration duration;
  final VoidCallback onShare;
  final DateTime? start;
  final DateTime? end;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AnimatedCheck(),
        const SizedBox(height: AppSpacing.md),
        Text(
          'STRYK SECURED',
          style: AppTypography.label.copyWith(color: AppColors.amber, letterSpacing: 2),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Day $day', style: AppTypography.heading),
        if (start != null && end != null) ...[
          const SizedBox(height: 6),
          Text(
            Dates.timeRange(start!, end!),
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
        Text(
          Dates.friendlyDuration(duration),
          style: AppTypography.body.copyWith(color: AppColors.amber),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        StrykButton(label: 'Get Your Card', onPressed: onShare),
      ],
    );
  }
}
