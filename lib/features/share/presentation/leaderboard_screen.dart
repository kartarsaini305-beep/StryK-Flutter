import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/share/models/monthly_result.dart';
import '../../../features/share/services/monthly_leaderboard_service.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/stryk_button.dart';
import '../../../widgets/stryk_card.dart';
import '../../../widgets/stryk_logo.dart';

/// Monthly gym leaderboard + my rank. Uses real synced entries only.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  List<MonthlyPlace> _gymTop = const [];
  List<MonthlyPlace> _globalTop = const [];
  var _tab = 0; // 0 = Gym, 1 = My Rank
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    final app = ref.read(appControllerProvider);
    final month = MonthlyLeaderboardService.monthKey();
    final days = MonthlyLeaderboardService.verifiedDaysForMonth(
      app.records,
      month,
    );
    final user = app.user;
    final gymName = app.effectiveGym?.name ?? '';
    final local = user == null
        ? null
        : MonthlyPlace(
            userId: user.id.isEmpty ? 'local-user' : user.id,
            displayName: user.name.trim().isEmpty ? 'You' : user.name.trim(),
            verifiedDays: days,
            gymName: gymName,
            rank: 1,
          );

    final instant = (local != null && days > 0)
        ? [local]
        : const <MonthlyPlace>[];
    setState(() {
      _gymTop = instant;
      _globalTop = instant;
      _loading = instant.isEmpty;
      _error = null;
    });

    try {
      if (local != null && days > 0) {
        unawaited(
          MonthlyLeaderboardService().syncUserEntry(
            userId: local.userId,
            displayName: local.displayName,
            verifiedDays: days,
            gymName: local.gymName,
          ),
        );
      }
      final service = MonthlyLeaderboardService();
      final global = await service.fetchTop(
        month: month,
        limit: 5,
        localFallback: local,
      );
      final gym = gymName.isEmpty
          ? global
          : await service.fetchGymTop(
              gymName: gymName,
              month: month,
              limit: 5,
              localFallback: local,
            );
      if (!mounted) return;
      setState(() {
        _globalTop = global;
        _gymTop = gym;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_gymTop.isEmpty && _globalTop.isEmpty) {
          _error = 'Unable to load leaderboard.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final monthLabel = DateFormat('MMM yyyy').format(DateTime.now());
    final gymName = app.effectiveGym?.name ?? '';
    final myId = app.user?.id.isEmpty == true
        ? 'local-user'
        : (app.user?.id ?? '');
    final board = _tab == 0 ? _gymTop : _globalTop;
    MonthlyPlace? myPlace;
    for (final p in board) {
      if (p.userId == myId) {
        myPlace = p;
        break;
      }
    }
    final myStreak = app.streak.current;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Monthly Leaderboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    monthLabel,
                    style: AppTypography.label.copyWith(color: AppColors.amber),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.calendar_today_rounded,
                      size: 14, color: AppColors.amber.withValues(alpha: 0.8)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.amber),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, style: AppTypography.body),
                          const SizedBox(height: 12),
                          StrykButton(
                            label: 'Retry',
                            variant: StrykButtonVariant.secondary,
                            onPressed: _load,
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                          children: [
                            const StrykLogo(
                              height: 22,
                              variant: StrykLogoVariant.wordmark,
                            ),
                            const SizedBox(height: 14),
                            _SegmentTabs(
                              index: _tab,
                              onChanged: (i) => setState(() => _tab = i),
                            ),
                            const SizedBox(height: 14),
                            _HeaderBanner(
                              title: _tab == 0
                                  ? 'Top 5 in Your Gym'
                                  : 'Your Monthly Standing',
                              subtitle: _tab == 0
                                  ? (gymName.isEmpty
                                      ? 'Select a gym to filter the board.'
                                      : 'Consistent effort builds real results.')
                                  : 'Global Top 5 by verified gym days this month.',
                            ),
                            const SizedBox(height: 14),
                            if (board.isEmpty)
                              StrykCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'No leaderboard data yet',
                                      style: AppTypography.subheading,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _tab == 0 && gymName.isEmpty
                                          ? 'Choose a gym, then complete a verified session.'
                                          : 'Complete a verified gym session this month to appear. Other athletes show up after they sync — names are never invented.',
                                      style: AppTypography.body,
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton(
                                      onPressed: _load,
                                      child: Text(
                                        'Refresh',
                                        style: AppTypography.bodyMedium
                                            .copyWith(color: AppColors.amber),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else ...[
                              for (final place in board)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _RankRow(
                                    place: place,
                                    isYou: place.userId == myId,
                                    // Streak is local-only — show only for the signed-in user.
                                    streak: place.userId == myId
                                        ? myStreak
                                        : null,
                                  ),
                                ),
                              if (board.length < 2)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Only synced athletes appear here. Invite gym friends — their ranks show after they check in and sync.',
                                    style: AppTypography.label.copyWith(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                      if (myPlace != null ||
                          (app.user != null &&
                              MonthlyLeaderboardService.verifiedDaysForMonth(
                                    app.records,
                                    MonthlyLeaderboardService.monthKey(),
                                  ) >
                                  0))
                        _YourRankBar(
                          rank: myPlace?.rank,
                          gymName: gymName.isEmpty
                              ? (myPlace?.gymName ?? 'your gym')
                              : gymName,
                          onTap: () => setState(() => _tab = 1),
                        ),
                    ],
                  ),
      ),
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Seg(
              label: 'Gym Leaderboard',
              selected: index == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _Seg(
              label: 'My Rank',
              selected: index == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.amber : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(
              color: selected ? AppColors.textOnLight : AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return StrykCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.subheading.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.body.copyWith(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.place,
    required this.isYou,
    this.streak,
  });

  final MonthlyPlace place;
  final bool isYou;
  final int? streak;

  @override
  Widget build(BuildContext context) {
    final rankColor = place.rank == 1 ? AppColors.amber : AppColors.textSecondary;
    final initial =
        place.displayName.isEmpty ? '?' : place.displayName[0].toUpperCase();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isYou
              ? AppColors.amber.withValues(alpha: 0.75)
              : AppColors.borderSubtle,
          width: isYou ? 1.5 : 1,
        ),
        boxShadow: isYou
            ? const [
                BoxShadow(color: AppColors.amberGlow, blurRadius: 16),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: place.rank == 1
                  ? AppColors.amber.withValues(alpha: 0.2)
                  : AppColors.charcoalDeep,
              border: Border.all(color: rankColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              '${place.rank}',
              style: AppTypography.label.copyWith(
                color: rankColor,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.charcoalDeep,
            child: Text(
              initial,
              style: AppTypography.subheading.copyWith(
                color: AppColors.amber,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isYou ? 'You' : place.displayName,
                  style: AppTypography.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (place.gymName.isNotEmpty)
                  Text(
                    place.gymName,
                    style: AppTypography.label.copyWith(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${place.verifiedDays} days',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.amber,
                  fontSize: 13,
                ),
              ),
              if (streak != null && streak! > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 12,
                      color: AppColors.amber.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$streak',
                      style: AppTypography.label.copyWith(fontSize: 10),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _YourRankBar extends StatelessWidget {
  const _YourRankBar({
    required this.rank,
    required this.gymName,
    required this.onTap,
  });

  final int? rank;
  final String gymName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: AppColors.amber,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Rank', style: AppTypography.label),
                      Text(
                        rank == null
                            ? 'Unranked in $gymName'
                            : '#$rank in $gymName',
                        style: AppTypography.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
