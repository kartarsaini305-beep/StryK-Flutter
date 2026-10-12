import 'package:flutter/material.dart';

import '../../features/share/models/monthly_result.dart';
import '../../features/sponsors/presentation/sponsor_logo.dart';
import '../../widgets/stryk_logo.dart';
import '../theme/app_theme.dart';

/// Shareable monthly leaderboard card — 4:5. Fits canvas with no scroll/overflow.
class MonthlyChampionCard extends StatelessWidget {
  const MonthlyChampionCard({
    super.key,
    required this.result,
  });

  final MonthlyResult result;

  static const aspectRatio = 4 / 5;

  @override
  Widget build(BuildContext context) {
    final top = result.topFive.take(5).toList();
    final p1 = top.isNotEmpty ? top[0] : null;
    final p2 = top.length > 1 ? top[1] : null;
    final p3 = top.length > 2 ? top[2] : null;
    final rest = top.length > 3 ? top.sublist(3) : const <MonthlyPlace>[];
    final sponsors = result.effectiveSponsors;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final s = (constraints.maxWidth / 360).clamp(0.65, 1.1);
            return DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.35),
                  radius: 1.2,
                  colors: [
                    Color(0xFF241C08),
                    Color(0xFF0A0A0A),
                    Color(0xFF000000),
                  ],
                  stops: [0, 0.55, 1],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16 * s, 16 * s, 16 * s, 14 * s),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'REAL PEOPLE · REAL GYMS',
                            style: AppTypography.label.copyWith(
                              fontSize: 7 * s,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          result.monthShort.toUpperCase(),
                          style: AppTypography.label.copyWith(
                            fontSize: 7 * s,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8 * s),
                    StrykLogo(height: 22 * s, light: true),
                    SizedBox(height: 4 * s),
                    Text(
                      'SHOW UP · STAY CONSISTENT',
                      style: AppTypography.label.copyWith(
                        fontSize: 7.5 * s,
                        letterSpacing: 1.2,
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(height: 10 * s),
                    Text(
                      'MONTHLY CHAMPIONS',
                      textAlign: TextAlign.center,
                      style: AppTypography.heading.copyWith(
                        fontSize: 20 * s,
                        color: AppColors.amber,
                        height: 1.05,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'TOP 5 · ${result.monthLabel}',
                      style: AppTypography.label.copyWith(
                        fontSize: 8 * s,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 10 * s),
                    Expanded(
                      flex: 11,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: p2 == null
                                ? const SizedBox.shrink()
                                : _Podium(
                                    place: p2,
                                    metal: const Color(0xFFC0C0C0),
                                    scale: s,
                                    winner: false,
                                  ),
                          ),
                          Expanded(
                            flex: 13,
                            child: p1 == null
                                ? const SizedBox.shrink()
                                : _Podium(
                                    place: p1,
                                    metal: AppColors.amber,
                                    scale: s,
                                    winner: true,
                                  ),
                          ),
                          Expanded(
                            child: p3 == null
                                ? const SizedBox.shrink()
                                : _Podium(
                                    place: p3,
                                    metal: const Color(0xFFCD7F32),
                                    scale: s,
                                    winner: false,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    if (rest.isNotEmpty) ...[
                      SizedBox(height: 6 * s),
                      for (final p in rest)
                        Padding(
                          padding: EdgeInsets.only(bottom: 4 * s),
                          child: _RankRow(place: p, scale: s),
                        ),
                    ],
                    const Spacer(flex: 1),
                    if (sponsors.isNotEmpty) ...[
                      _SponsorsBlock(sponsors: sponsors, scale: s),
                      SizedBox(height: 6 * s),
                    ],
                    Text(
                      result.tagline,
                      style: AppTypography.label.copyWith(
                        color: AppColors.amber,
                        fontSize: 9 * s,
                        letterSpacing: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2 * s),
                    Text(
                      "YOU DIDN'T JUST SHOW UP. YOU OWNED THE MONTH.",
                      textAlign: TextAlign.center,
                      style: AppTypography.label.copyWith(
                        fontSize: 7 * s,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({
    required this.place,
    required this.metal,
    required this.scale,
    required this.winner,
  });

  final MonthlyPlace place;
  final Color metal;
  final double scale;
  final bool winner;

  @override
  Widget build(BuildContext context) {
    final initial =
        place.displayName.isEmpty ? '?' : place.displayName[0].toUpperCase();
    return LayoutBuilder(
      builder: (context, c) {
        final barH = (c.maxHeight * (winner ? 0.42 : 0.32)).clamp(40.0, 90.0);
        final avatar = (winner ? 26.0 : 20.0) * scale;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (winner)
              Icon(Icons.emoji_events_rounded, color: metal, size: 14 * scale),
            Container(
              width: avatar * 2,
              height: avatar * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: metal, width: winner ? 2 : 1.2),
                color: AppColors.charcoal,
                boxShadow: [
                  BoxShadow(
                    color: metal.withValues(alpha: 0.3),
                    blurRadius: 10 * scale,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: AppTypography.subheading.copyWith(
                  color: metal,
                  fontSize: avatar * 0.9,
                ),
              ),
            ),
            SizedBox(height: 3 * scale),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 6 * scale,
                vertical: 1.5 * scale,
              ),
              decoration: BoxDecoration(
                color: metal.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: metal.withValues(alpha: 0.5)),
              ),
              child: Text(
                '#${place.rank}',
                style: AppTypography.label.copyWith(
                  color: metal,
                  fontSize: 8 * scale,
                ),
              ),
            ),
            SizedBox(height: 4 * scale),
            SizedBox(
              height: barH,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      metal.withValues(alpha: 0.32),
                      AppColors.charcoal,
                    ],
                  ),
                  border: Border.all(color: metal.withValues(alpha: 0.4)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3 * scale),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (winner)
                        Text(
                          'WINNER',
                          style: AppTypography.label.copyWith(
                            color: metal,
                            fontSize: 7 * scale,
                          ),
                        ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          place.displayName.toUpperCase(),
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: (winner ? 11 : 9) * scale,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      if (place.gymName.isNotEmpty)
                        Text(
                          place.gymName,
                          style: AppTypography.label.copyWith(
                            fontSize: 6 * scale,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${place.verifiedDays}',
                          style: AppTypography.metric.copyWith(
                            fontSize: (winner ? 20 : 15) * scale,
                            color: metal,
                          ),
                        ),
                      ),
                      Text(
                        'GYM DAYS',
                        style: AppTypography.label.copyWith(
                          fontSize: 6.5 * scale,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.place, required this.scale});
  final MonthlyPlace place;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 7 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26 * scale,
            child: Text(
              '#${place.rank}',
              style: AppTypography.label.copyWith(
                color: AppColors.amber,
                fontSize: 10 * scale,
              ),
            ),
          ),
          Expanded(
            child: Text(
              place.displayName.toUpperCase(),
              style: AppTypography.bodyMedium.copyWith(fontSize: 11 * scale),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (place.gymName.isNotEmpty) ...[
            Icon(Icons.location_on, size: 11 * scale, color: AppColors.amber),
            SizedBox(width: 3 * scale),
            Flexible(
              child: Text(
                place.gymName,
                style: AppTypography.label.copyWith(
                  fontSize: 8 * scale,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 6 * scale),
          ],
          Text(
            '${place.verifiedDays}',
            style: AppTypography.metric.copyWith(
              fontSize: 14 * scale,
              color: AppColors.amber,
            ),
          ),
        ],
      ),
    );
  }
}

class _SponsorsBlock extends StatelessWidget {
  const _SponsorsBlock({required this.sponsors, required this.scale});
  final List<SponsorSnapshot> sponsors;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.35)),
        color: AppColors.charcoal.withValues(alpha: 0.7),
      ),
      child: Column(
        children: [
          Text(
            sponsors.length == 1 ? 'POWERED BY' : 'SPONSORS',
            style: AppTypography.label.copyWith(
              color: AppColors.amber,
              fontSize: 8 * scale,
            ),
          ),
          SizedBox(height: 6 * scale),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10 * scale,
            runSpacing: 6 * scale,
            children: [
              for (final s in sponsors.take(5))
                SizedBox(
                  width: sponsors.length == 1 ? 140 * scale : 72 * scale,
                  child: Column(
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 28 * scale,
                          maxWidth:
                              sponsors.length == 1 ? 120 * scale : 56 * scale,
                        ),
                        child: SponsorLogo(
                          urlOrPath: s.logoUrl,
                          fallbackIconSize: 18 * scale,
                        ),
                      ),
                      SizedBox(height: 3 * scale),
                      Text(
                        s.name,
                        style: AppTypography.label.copyWith(
                          fontSize: 7.5 * scale,
                          color: AppColors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
