import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_copy.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/geo.dart';
import '../../../core/utils/greeting.dart';
import '../../../core/widgets/demo_chrome.dart';
import '../../../core/widgets/demo_mode_panel.dart';
import '../../../core/widgets/ds/stryk_section_header.dart';
import '../../../core/widgets/session_timer.dart';
import '../../../core/widgets/weekly_strip.dart';
import '../../../features/sponsors/models/sponsor.dart';
import '../../../features/sponsors/presentation/sponsor_logo.dart';
import '../../../features/sponsors/services/sponsor_repository.dart';
import '../../../features/share/services/monthly_leaderboard_service.dart';
import '../../../providers/app_controller.dart';
import '../../../providers/app_state.dart';
import '../../../widgets/pressable_scale.dart';
import '../../../widgets/stryk_button.dart';
import '../../../widgets/stryk_card.dart';
import '../../../widgets/stryk_logo.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Sponsor> _sponsors = const [];

  @override
  void initState() {
    super.initState();
    _loadSponsors();
  }

  Future<void> _loadSponsors() async {
    final gymId = ref.read(appControllerProvider).gym?.id;
    final list = await SponsorRepository().fetchActive(
      gymId: gymId,
      limit: 5,
      placement: SponsorPlacement.app,
    );
    if (mounted) setState(() => _sponsors = list);
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    ref.watch(tickerProvider);
    final name = app.user?.name.trim().split(' ').first ?? '';
    final greeting = Greeting.of(DateTime.now());
    final photo = app.user?.photoPath;
    final monthKey = Dates.key(DateTime.now()).substring(0, 7);
    final monthly = app.records.values.where((r) {
      return r.isCompleted && r.dateKey.startsWith(monthKey);
    }).length;

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      Builder(
                        builder: (ctx) => IconButton(
                          tooltip: 'Menu',
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                          icon: const Icon(Icons.menu_rounded, size: 22),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: StrykLogo(
                            height: 22,
                            variant: StrykLogoVariant.wordmark,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Notifications',
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_none_rounded, size: 22),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.profile),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.charcoal,
                          backgroundImage:
                              photo != null && File(photo).existsSync()
                                  ? FileImage(File(photo))
                                  : null,
                          child: photo == null
                              ? Text(
                                  name.isEmpty ? 'S' : name[0].toUpperCase(),
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.amber,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: DemoModeBadge(onTap: () => DemoModePanel.show(context)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name.isEmpty ? greeting : '$greeting, $name',
                    style: AppTypography.heading.copyWith(fontSize: 26),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  StrykCard(
                    glow: app.streak.current > 0,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.amber.withValues(alpha: 0.12),
                            border: Border.all(
                              color: AppColors.amber.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: AppColors.amber,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CURRENT STREAK',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.amber,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${app.streak.current}',
                                        style: AppTypography.display.copyWith(
                                          fontSize: 40,
                                          color: AppColors.amber,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' days',
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Text(
                                'Best ${app.streak.best} · Lifetime ${app.streak.totalGymDays}',
                                style: AppTypography.body.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        _MiniStat(label: 'Month', value: '$monthly'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _TodaySessionCard(),
                  const SizedBox(height: 12),
                  _GymStatusCard(app: app),
                  const SizedBox(height: 22),
                  StrykSectionHeader(
                    title: 'This week',
                    trailing: TextButton(
                      onPressed: () => context.push(AppRoutes.leaderboard),
                      child: Text(
                        'Leaderboard',
                        style: AppTypography.label.copyWith(color: AppColors.amber),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  WeeklyStrip(
                    records: app.records,
                    onDayTap: (day) {
                      final key = Dates.key(day);
                      if (app.records[key] != null) {
                        context.push(AppRoutes.dayFor(key));
                      }
                    },
                  ),
                  const SizedBox(height: 26),
                  StrykSectionHeader(
                    title: 'Sponsored this month',
                    subtitle: _sponsors.isEmpty
                        ? null
                        : '${_sponsors.length} brand${_sponsors.length == 1 ? '' : 's'} powering your consistency',
                    trailing: TextButton(
                      onPressed: () => context.push(AppRoutes.monthlyResult),
                      child: Text(
                        'Results',
                        style: AppTypography.label.copyWith(color: AppColors.amber),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_sponsors.isEmpty)
                    StrykCard(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.charcoal,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: const Icon(
                              Icons.handshake_outlined,
                              color: AppColors.amber,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SPONSORED THIS MONTH',
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.amber,
                                    fontSize: 9,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppCopy.sponsorEmptyUser,
                                  style: AppTypography.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 148,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _sponsors.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, i) => _SponsorTile(sponsor: _sponsors[i]),
                      ),
                    ),
                  const SizedBox(height: 22),
                  const StrykSectionHeader(title: 'Quick actions'),
                  const SizedBox(height: 10),
                  const _QuickActions(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: AppTypography.metric.copyWith(fontSize: 20)),
          Text(label.toUpperCase(), style: AppTypography.label.copyWith(fontSize: 9)),
        ],
      ),
    );
  }
}

class _SponsorTile extends StatelessWidget {
  const _SponsorTile({required this.sponsor});
  final Sponsor sponsor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: StrykCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: ColoredBox(
                      color: AppColors.charcoal,
                      child: SponsorLogo(
                        urlOrPath: sponsor.logoUrl,
                        fit: BoxFit.cover,
                        fallbackIconSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sponsor.tier.toUpperCase(),
                    style: AppTypography.label.copyWith(
                      color: AppColors.amber,
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              sponsor.name,
              style: AppTypography.subheading.copyWith(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              sponsor.campaignName.isEmpty ? sponsor.challenge : sponsor.campaignName,
              style: AppTypography.body.copyWith(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              sponsor.offer.isEmpty ? sponsor.cta : sponsor.offer,
              style: AppTypography.label.copyWith(color: AppColors.amber, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaySessionCard extends ConsumerWidget {
  const _TodaySessionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    ref.watch(tickerProvider);
    final status = app.todayStatus();
    final todayKey = Dates.key(DateTime.now());
    final minStay = app.minStay.inMinutes;
    final radius = app.checkInRadiusMeters.round();

    return StrykCard(
      padding: const EdgeInsets.all(18),
      child: switch (status) {
        TodayStatus.notStarted => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("TODAY'S STRYK", style: AppTypography.label),
              const SizedBox(height: 10),
              Text('You\'re ready?', style: AppTypography.subheading),
              const SizedBox(height: 6),
              Text(
                'Move within ${radius}m of your gym, then check in. Stay $minStay min to secure today.',
                style: AppTypography.body,
              ),
              const SizedBox(height: 14),
              StrykButton(
                label: 'Open demo location',
                variant: StrykButtonVariant.secondary,
                onPressed: () => DemoModePanel.show(context),
              ),
            ],
          ),
        TodayStatus.readyToCheckIn => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("TODAY'S STRYK", style: AppTypography.label),
              const SizedBox(height: 10),
              Text('You\'re in the zone', style: AppTypography.subheading),
              const SizedBox(height: 6),
              Text('Within ${radius}m. Tap Check In to start.', style: AppTypography.body),
              const SizedBox(height: 14),
              StrykButton(
                label: 'Check In at Gym',
                icon: Icons.login_rounded,
                onPressed: () async {
                  final ok = await ref.read(appControllerProvider.notifier).checkIn();
                  if (!context.mounted) return;
                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.charcoal,
                        content: Text('Move closer to check in.', style: AppTypography.bodyMedium),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        TodayStatus.tracking => _ActiveSessionBlock(
            secured: false,
            onEnd: null,
          ),
        TodayStatus.secured => _ActiveSessionBlock(
            secured: true,
            onEnd: () => ref.read(appControllerProvider.notifier).checkoutSession(),
          ),
        TodayStatus.leavingZone => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'OUTSIDE THE ZONE',
                style: AppTypography.label.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Center(
                child: SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (final r in [1.0, 0.72, 0.48])
                        Container(
                          width: 160 * r,
                          height: 160 * r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.25 * r),
                            ),
                          ),
                        ),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Checkout in ${_fmt(app.outsideCountdown())}',
                style: AppTypography.heading.copyWith(
                  fontSize: 28,
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Move back inside the gym perimeter',
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              StrykButton(
                label: 'Back Inside',
                onPressed: () =>
                    ref.read(appControllerProvider.notifier).simulateEnterZone(),
              ),
            ],
          ),
        TodayStatus.interrupted => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('SESSION INTERRUPTED', style: AppTypography.label),
              const SizedBox(height: 8),
              Text(
                'You left before the minimum stay. Return and check in again.',
                style: AppTypography.body,
              ),
              const SizedBox(height: 14),
              StrykButton(
                label: 'Try again',
                onPressed: () =>
                    ref.read(appControllerProvider.notifier).retryAfterInterrupt(),
              ),
            ],
          ),
        TodayStatus.completed => _SessionCompleteBlock(
            app: app,
            todayKey: todayKey,
          ),
      },
    );
  }

  String _fmt(Duration? d) {
    if (d == null) return '--:--';
    final total = d.inSeconds.clamp(0, 3600);
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _ActiveSessionBlock extends ConsumerWidget {
  const _ActiveSessionBlock({required this.secured, this.onEnd});
  final bool secured;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(tickerProvider);
    final state = ref.watch(appControllerProvider);
    final elapsed = state.elapsed();
    final remaining = state.remaining();
    final minStay = state.minStay;
    final stayProgress = secured
        ? 1.0
        : (elapsed.inMilliseconds / minStay.inMilliseconds).clamp(0.0, 1.0);
    final score = (elapsed.inMinutes * 12).clamp(0, 9999);
    final gym = state.effectiveGym?.name ?? 'Gym';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          secured ? 'STREAK SECURED' : 'ACTIVE SESSION',
          style: AppTypography.label.copyWith(
            color: secured ? AppColors.amber : AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          gym,
          style: AppTypography.body.copyWith(fontSize: 13),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
        const Center(
          child: SessionTimer(compact: false, showMeter: false, showCaption: false),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'StryK Score',
                value: '$score',
                accent: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'Streak',
                value: '${state.streak.current}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'MIN. STAY PROGRESS',
          style: AppTypography.label.copyWith(fontSize: 10),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: stayProgress,
            minHeight: 6,
            backgroundColor: AppColors.charcoal,
            color: AppColors.amber,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          secured
              ? 'Minimum stay met · timer continues until checkout'
              : '${remaining.inMinutes.clamp(0, 999)} min left · ${minStay.inMinutes} min required',
          style: AppTypography.body.copyWith(fontSize: 12),
        ),
        if (secured) ...[
          const SizedBox(height: 14),
          AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: AppColors.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Streak Secured — keep training or check out when done.',
                    style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (onEnd != null) ...[
          const SizedBox(height: 14),
          StrykButton(
            label: 'Check Out',
            variant: StrykButtonVariant.secondary,
            onPressed: onEnd,
          ),
        ],
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.accent = false,
  });
  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: accent
              ? AppColors.amber.withValues(alpha: 0.35)
              : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.label.copyWith(fontSize: 9),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.metric.copyWith(
              fontSize: 22,
              color: accent ? AppColors.amber : AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCompleteBlock extends ConsumerStatefulWidget {
  const _SessionCompleteBlock({required this.app, required this.todayKey});
  final AppState app;
  final String todayKey;

  @override
  ConsumerState<_SessionCompleteBlock> createState() =>
      _SessionCompleteBlockState();
}

class _SessionCompleteBlockState extends ConsumerState<_SessionCompleteBlock> {
  int? _rank;
  var _loadingRank = true;

  @override
  void initState() {
    super.initState();
    _loadRank();
  }

  Future<void> _loadRank() async {
    final app = ref.read(appControllerProvider);
    final user = app.user;
    final gym = app.effectiveGym?.name ?? '';
    if (user == null || gym.isEmpty) {
      setState(() => _loadingRank = false);
      return;
    }
    final month = MonthlyLeaderboardService.monthKey();
    final days = MonthlyLeaderboardService.verifiedDaysForMonth(
      widget.app.records,
      month,
    );
    final rank = await MonthlyLeaderboardService().gymRankForUser(
      userId: user.id.isEmpty ? 'local-user' : user.id,
      gymName: gym,
      month: month,
      localVerifiedDays: days,
      displayName: user.name,
    );
    if (!mounted) return;
    setState(() {
      _rank = rank;
      _loadingRank = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.app.todayRecord();
    final duration = record?.duration ?? widget.app.elapsed();
    final score = (duration.inMinutes * 12).clamp(0, 9999);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: StrykLogo(height: 36, light: true)),
        const SizedBox(height: 12),
        Text(
          'SESSION COMPLETE',
          style: AppTypography.label.copyWith(color: AppColors.amber),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          Dates.friendlyDuration(duration),
          style: AppTypography.heading.copyWith(fontSize: 32),
          textAlign: TextAlign.center,
        ),
        if (record?.arrivalTime != null && record?.endTime != null)
          Text(
            Dates.timeRange(record!.arrivalTime!, record.endTime!),
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricTile(label: 'StryK Score', value: '$score', accent: true),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'Streak',
                value: '${widget.app.streak.current}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Text('GYM RANK', style: AppTypography.label.copyWith(fontSize: 10)),
              const SizedBox(height: 4),
              if (_loadingRank)
                Text('Loading…', style: AppTypography.body)
              else if (_rank != null)
                Text(
                  '#$_rank IN YOUR GYM',
                  style: AppTypography.subheading.copyWith(color: AppColors.amber),
                  textAlign: TextAlign.center,
                )
              else
                Text(
                  'Gym rank updates after your next verified session.',
                  style: AppTypography.body.copyWith(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StrykButton(
          label: 'Get Your Card',
          onPressed: () => context.push(AppRoutes.shareFor(widget.todayKey)),
        ),
      ],
    );
  }
}

class _GymStatusCard extends StatelessWidget {
  const _GymStatusCard({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final gym = app.effectiveGym;
    if (gym == null) {
      return const EmptyState(
        title: 'Choose your gym',
        message: 'Select one gym so StryK can detect when you show up.',
      );
    }
    final meters = app.distanceToGymMeters();
    final inside = app.isInsideCheckIn;
    return StrykCard(
      child: Row(
        children: [
          Icon(
            inside ? Icons.location_on : Icons.location_on_outlined,
            color: inside ? AppColors.amber : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gym.name, style: AppTypography.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  inside ? "You're in the zone" : '${meters.round()}m · Move closer',
                  style: AppTypography.label.copyWith(
                    color: inside ? AppColors.success : AppColors.textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatDistance(meters).replaceAll(' away', ''),
            style: AppTypography.label.copyWith(color: AppColors.amber),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Action(icon: Icons.calendar_month_rounded, label: 'Activity', onTap: () => context.go(AppRoutes.history)),
        const SizedBox(width: 10),
        _Action(icon: Icons.style_rounded, label: 'Cards', onTap: () => context.go(AppRoutes.cards)),
        const SizedBox(width: 10),
        _Action(icon: Icons.emoji_events_outlined, label: 'Board', onTap: () => context.push(AppRoutes.leaderboard)),
        const SizedBox(width: 10),
        _Action(icon: Icons.tune_rounded, label: 'Demo', onTap: () => DemoModePanel.show(context)),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PressableScale(
        scale: 0.96,
        onPressed: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Icon(icon, color: AppColors.amber, size: 20),
                const SizedBox(height: 6),
                Text(label, style: AppTypography.label.copyWith(fontSize: 10, letterSpacing: 0.2), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
