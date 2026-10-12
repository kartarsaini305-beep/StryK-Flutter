import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/monthly_champion_card.dart';
import '../../../features/share/models/monthly_result.dart';
import '../../../features/share/services/monthly_leaderboard_service.dart';
import '../../../features/share/services/monthly_result_repository.dart';
import '../../../features/share/services/share_card_exporter.dart';
import '../../../features/sponsors/models/sponsor.dart';
import '../../../features/sponsors/services/sponsor_repository.dart';
import '../../../core/utils/month_weekend.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/stryk_button.dart';
import '../../../widgets/stryk_card.dart';
import '../../../widgets/stryk_logo.dart';

class MonthlyResultScreen extends ConsumerStatefulWidget {
  const MonthlyResultScreen({super.key});

  @override
  ConsumerState<MonthlyResultScreen> createState() =>
      _MonthlyResultScreenState();
}

class _MonthlyResultScreenState extends ConsumerState<MonthlyResultScreen> {
  final _exportKey = GlobalKey();
  final _repo = MonthlyResultRepository();
  MonthlyResult? _selected;
  List<MonthlyResult> _history = const [];
  var _loading = true;
  var _sharing = false;
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final month = MonthlyResultRepository.monthKey();
      final published = await _repo.fetchPublished();
      var current = await _repo.fetch(month);
      if (current == null || !current.isFinal) {
        current = await _buildPreview(month);
      }
      if (!mounted) return;
      setState(() {
        _history = published;
        _selected = current;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Monthly results could not be loaded.';
      });
    }
  }

  Future<MonthlyResult> _buildPreview(String month) async {
    final app = ref.read(appControllerProvider);
    final days = MonthlyLeaderboardService.verifiedDaysForMonth(
      app.records,
      month,
    );
    final user = app.user;
    final local = user == null
        ? null
        : MonthlyPlace(
            userId: user.id.isEmpty ? 'local-user' : user.id,
            displayName: user.name.trim().isEmpty ? 'You' : user.name.trim(),
            verifiedDays: days,
            gymName: app.effectiveGym?.name ?? '',
          );
    final top = await MonthlyLeaderboardService().fetchTop(
      month: month,
      limit: 5,
      localFallback: local,
    );
    final sponsors = await SponsorRepository().fetchActive(
      limit: 5,
      placement: SponsorPlacement.monthlyCard,
    );
    final snaps = MonthlyResultRepository.snapshotsFrom(sponsors);
    return MonthlyResult(
      month: month,
      status: 'preview',
      topFive: top,
      sponsors: snaps,
      sponsorSnapshot: snaps.isEmpty ? null : snaps.first,
      tagline: 'CONSISTENCY WINS.',
    );
  }

  Future<void> _share() async {
    if (_sharing || _selected == null) return;
    final isAdmin = ref.read(appControllerProvider).adminAuthenticated;
    if (!MonthWeekend.isLastWeekendOfMonth() && !isAdmin) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.charcoal,
          content: Text(
            'Share opens on the last weekend (${MonthWeekend.windowLabel()}). Top 5 is always visible.',
            style: AppTypography.bodyMedium,
          ),
        ),
      );
      return;
    }
    setState(() => _sharing = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      final file = await const ShareCardExporter().capturePng(
        _exportKey,
        pixelRatio: 3,
      );
      await const ShareCardExporter().shareFile(
        file,
        text: 'StryK Monthly Leaderboard — ${_selected!.monthLabel}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.charcoal,
          content: Text(
            'Could not share card. $e',
            style: AppTypography.bodyMedium,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Monthly Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.amber),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: AppTypography.body),
                        StrykButton(
                          label: 'Retry',
                          variant: StrykButtonVariant.secondary,
                          onPressed: _load,
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    children: [
                      const StrykLogo(height: 24, light: true),
                      const SizedBox(height: 12),
                      Text(
                        _selected?.isFinal == true
                            ? 'MONTHLY RESULTS'
                            : 'PREVIEW',
                        style: AppTypography.label.copyWith(
                          color: AppColors.amber,
                        ),
                      ),
                      Text(
                        _selected?.monthLabel ??
                            DateFormat('MMMM yyyy')
                                .format(DateTime.now())
                                .toUpperCase(),
                        style: AppTypography.heading.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selected?.isFinal == true
                            ? 'Finalized Top 5. Rankings are locked for this month.'
                            : 'Live Top 5 preview — always visible. Share unlocks on the last weekend.',
                        style: AppTypography.body.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      if (_selected == null || _selected!.topFive.isEmpty)
                        StrykCard(
                          child: Text(
                            'No monthly results yet.',
                            style: AppTypography.body,
                          ),
                        )
                      else ...[
                        RepaintBoundary(
                          key: _exportKey,
                          child: MonthlyChampionCard(result: _selected!),
                        ),
                        const SizedBox(height: 16),
                        Builder(
                          builder: (context) {
                            final isAdmin = ref
                                .watch(appControllerProvider)
                                .adminAuthenticated;
                            final canShare = MonthWeekend.isLastWeekendOfMonth() ||
                                isAdmin;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (!canShare)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      'Share unlocks ${MonthWeekend.windowLabel()} (last weekend).',
                                      style: AppTypography.label.copyWith(
                                        color: AppColors.amber,
                                        fontSize: 11,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                StrykButton(
                                  label: canShare
                                      ? 'Share leaderboard card'
                                      : 'Share locked until last weekend',
                                  loading: _sharing,
                                  enabled:
                                      _selected!.topFive.isNotEmpty && canShare,
                                  onPressed: _share,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                      if (_history.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        Text('PREVIOUS MONTHS', style: AppTypography.label),
                        const SizedBox(height: 10),
                        for (final h in _history)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: StrykCard(
                              onTap: () => setState(() => _selected = h),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      h.monthLabel,
                                      style: AppTypography.bodyMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    'View',
                                    style: AppTypography.label
                                        .copyWith(color: AppColors.amber),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
      ),
    );
  }
}
