import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../features/share/models/share_payload.dart';
import '../../features/sponsors/presentation/sponsor_logo.dart';
import '../../widgets/stryk_logo.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';

class ShareCardCanvas extends StatelessWidget {
  const ShareCardCanvas({
    super.key,
    required this.payload,
    required this.style,
  });

  final SharePayload payload;
  final ShareCardStyle style;

  @override
  Widget build(BuildContext context) {
    // Key forces rebuild when the shared session photo changes.
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = (constraints.maxWidth / 320).clamp(0.72, 1.15);
          return KeyedSubtree(
            key: ValueKey('card-${style.name}-${payload.photoPath ?? 'none'}'),
            child: switch (style) {
              ShareCardStyle.minimal =>
                _MinimalCard(payload: payload, scale: scale),
              ShareCardStyle.photo =>
                _PhotoCard(payload: payload, scale: scale),
              ShareCardStyle.achievement =>
                _AchievementCard(payload: payload, scale: scale),
            },
          );
        },
      ),
    );
  }
}

class _VerifyMark extends StatelessWidget {
  const _VerifyMark({required this.payload, this.compact = false});

  final SharePayload payload;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 40.0;
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: QrImageView(
            data: payload.verificationUrl,
            size: size,
            padding: const EdgeInsets.all(2),
            backgroundColor: AppColors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF141414),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF141414),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            payload.verificationId,
            style: AppTypography.label.copyWith(
              fontSize: compact ? 8.5 : 10,
              color: AppColors.textMuted,
              letterSpacing: 0.6,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.text,
    this.color = AppColors.textSecondary,
    this.scale = 1,
  });

  final IconData icon;
  final String text;
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13 * scale, color: color),
        SizedBox(width: 6 * scale),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: color,
              fontSize: 12 * scale,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PhotoLayer extends StatelessWidget {
  const _PhotoLayer({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C1C1C), Color(0xFF0A0A0A)],
          ),
        ),
      );
    }
    final file = File(path!);
    if (!file.existsSync()) {
      return const ColoredBox(color: Color(0xFF121212));
    }
    return Image.file(
      file,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
    );
  }
}

class _MinimalCard extends StatelessWidget {
  const _MinimalCard({required this.payload, required this.scale});

  final SharePayload payload;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final pad = 18.0 * scale;
    final content = Padding(
      padding: EdgeInsets.fromLTRB(pad, pad, pad, pad * 0.85),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StrykLogo(height: 20 * scale, light: true),
              const Spacer(),
              Flexible(
                child: Text(
                  'VERIFIED',
                  style: AppTypography.label.copyWith(
                    fontSize: 8.5 * scale,
                    letterSpacing: 1.2,
                    color: AppColors.amber,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const Spacer(flex: 2),
          Text(
            'DAY ${payload.dayNumber}',
            style: AppTypography.label.copyWith(
              letterSpacing: 2,
              fontSize: 11 * scale,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8 * scale),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JUST',
                  style: AppTypography.display.copyWith(
                    fontSize: 40 * scale,
                    height: 0.95,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  'SHOWED UP.',
                  style: AppTypography.display.copyWith(
                    fontSize: 40 * scale,
                    height: 0.95,
                    color: AppColors.amber,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8 * scale),
          Container(width: 48 * scale, height: 2.5, color: AppColors.amber),
          const Spacer(),
          _MetaLine(
            icon: Icons.location_on_outlined,
            text:
                '${payload.gymName.toUpperCase()}  ·  ${Dates.upperDay(payload.date)}',
            scale: scale,
          ),
          SizedBox(height: 6 * scale),
          _MetaLine(
            icon: Icons.schedule,
            text: Dates.timeRange(payload.startTime, payload.endTime),
            scale: scale,
          ),
          SizedBox(height: 6 * scale),
          _MetaLine(
            icon: Icons.timer_outlined,
            text: Dates.sessionDurationLabel(payload.duration),
            color: AppColors.amber,
            scale: scale,
          ),
          SizedBox(height: 6 * scale),
          _MetaLine(
            icon: Icons.fitness_center,
            text:
                '${payload.totalGymDays} TOTAL GYM DAY${payload.totalGymDays == 1 ? '' : 'S'}',
            scale: scale,
          ),
          const Spacer(),
          if (payload.gymRank != null) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 10 * scale,
                vertical: 8 * scale,
              ),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
              ),
              child: Text(
                '#${payload.gymRank} IN YOUR GYM',
                textAlign: TextAlign.center,
                style: AppTypography.label.copyWith(
                  color: AppColors.amber,
                  fontSize: 10 * scale,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            SizedBox(height: 8 * scale),
          ] else ...[
            Text(
              'Gym rank updates after your next verified session.',
              style: AppTypography.label.copyWith(
                fontSize: 8 * scale,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8 * scale),
          ],
          if (payload.sponsors.isNotEmpty) ...[
            _DailySponsorsStrip(sponsors: payload.sponsors, scale: scale),
            SizedBox(height: 6 * scale),
          ],
          Row(
            children: [
              Flexible(
                child: Text(
                  'STRYK ${payload.dayNumber}',
                  style: AppTypography.subheading.copyWith(
                    color: AppColors.amber,
                    fontSize: 15 * scale,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8 * scale),
              Flexible(
                child: Text(
                  'CONSISTENCY BUILDS FREEDOM',
                  style: AppTypography.label.copyWith(
                    fontSize: 7.5 * scale,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * scale),
          _VerifyMark(payload: payload, compact: true),
        ],
      ),
    );

    // Session photo is shared — Minimal also shows it when present.
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF0E0E0E)),
        if (payload.photoPath != null) ...[
          _PhotoLayer(path: payload.photoPath),
          const ColoredBox(color: Color(0xCC0E0E0E)),
        ],
        content,
      ],
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.payload, required this.scale});

  final SharePayload payload;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0A0A0A),
      child: Column(
        children: [
          Expanded(
            flex: 7,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _PhotoLayer(path: payload.photoPath),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x66000000),
                        Color(0x00000000),
                        Color(0xF0000000),
                      ],
                      stops: [0, 0.45, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16 * scale,
                    16 * scale,
                    16 * scale,
                    14 * scale,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StrykLogo(height: 18 * scale, light: true),
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'DISCIPLINE\nBUILDS\nFREEDOM',
                          textAlign: TextAlign.right,
                          style: AppTypography.label.copyWith(
                            color: AppColors.white.withValues(alpha: 0.55),
                            letterSpacing: 1.4,
                            height: 1.3,
                            fontSize: 10 * scale,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'DAY ${payload.dayNumber}',
                        style: AppTypography.label.copyWith(
                          letterSpacing: 1.8,
                          fontSize: 11 * scale,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4 * scale),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'SHOWED UP.',
                          style: AppTypography.heading.copyWith(
                            fontSize: 26 * scale,
                            color: AppColors.amber,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16 * scale,
                12 * scale,
                16 * scale,
                12 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payload.gymName.toUpperCase(),
                    style: AppTypography.subheading.copyWith(fontSize: 14 * scale),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3 * scale),
                  Text(
                    '${Dates.upperDay(payload.date)}  ·  ${Dates.timeRange(payload.startTime, payload.endTime)}',
                    style: AppTypography.body.copyWith(fontSize: 11 * scale),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3 * scale),
                  Text(
                    '${Dates.sessionDurationLabel(payload.duration)}  ·  STRYK ${payload.dayNumber}',
                    style: AppTypography.label.copyWith(
                      color: AppColors.amber,
                      fontSize: 11 * scale,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  _VerifyMark(payload: payload, compact: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.payload, required this.scale});

  final SharePayload payload;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final name = payload.displayName.trim().isEmpty
        ? 'Athlete'
        : payload.displayName.trim();
    final initial = name[0].toUpperCase();
    final profile = payload.profilePhotoPath;
    final hasProfile =
        profile != null && profile.isNotEmpty && File(profile).existsSync();
    final verified = payload.verifiedDaysMonth ?? payload.totalGymDays;
    final current = payload.currentStreak ?? payload.dayNumber;
    final best = payload.bestStreak ?? current;

    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF0E0E0E)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (payload.photoPath != null) ...[
            _PhotoLayer(path: payload.photoPath),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.82),
                    const Color(0xF00B0B0B),
                  ],
                ),
              ),
            ),
          ] else
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.3),
                  radius: 1.1,
                  colors: [
                    AppColors.amber.withValues(alpha: 0.12),
                    const Color(0xFF0B0B0B),
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16 * scale,
              16 * scale,
              16 * scale,
              14 * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StrykLogo(
                      height: 18 * scale,
                      variant: StrykLogoVariant.wordmark,
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        'STRONGER EVERYDAY',
                        style: AppTypography.label.copyWith(
                          fontSize: 8 * scale,
                          color: AppColors.amber,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16 * scale),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22 * scale,
                      backgroundColor: AppColors.charcoal,
                      backgroundImage:
                          hasProfile ? FileImage(File(profile)) : null,
                      child: hasProfile
                          ? null
                          : Text(
                              initial,
                              style: AppTypography.subheading.copyWith(
                                color: AppColors.amber,
                                fontSize: 16 * scale,
                              ),
                            ),
                    ),
                    SizedBox(width: 10 * scale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTypography.subheading
                                .copyWith(fontSize: 15 * scale),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 12 * scale,
                                color: AppColors.amber,
                              ),
                              SizedBox(width: 2 * scale),
                              Expanded(
                                child: Text(
                                  payload.gymName,
                                  style: AppTypography.label
                                      .copyWith(fontSize: 10 * scale),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
                if (payload.gymRank != null) ...[
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '#${payload.gymRank}',
                      style: AppTypography.display.copyWith(
                        fontSize: 72 * scale,
                        height: 0.9,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  Text(
                    'IN YOUR GYM',
                    style: AppTypography.label.copyWith(
                      fontSize: 12 * scale,
                      color: AppColors.amber,
                      letterSpacing: 1.4,
                    ),
                  ),
                  Text(
                    'This Month',
                    style: AppTypography.body.copyWith(fontSize: 12 * scale),
                  ),
                ] else ...[
                  Text(
                    'DAY ${payload.dayNumber}',
                    style: AppTypography.display.copyWith(
                      fontSize: 48 * scale,
                      height: 1,
                      color: AppColors.amber,
                    ),
                  ),
                  Text(
                    'JUST SHOWED UP',
                    style: AppTypography.label.copyWith(
                      fontSize: 12 * scale,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: _StatCell(
                        icon: Icons.calendar_month_rounded,
                        label: 'Verified Days',
                        value: '$verified',
                        scale: scale,
                      ),
                    ),
                    Expanded(
                      child: _StatCell(
                        icon: Icons.local_fire_department_rounded,
                        label: 'Current Streak',
                        value: '$current',
                        scale: scale,
                      ),
                    ),
                    Expanded(
                      child: _StatCell(
                        icon: Icons.bar_chart_rounded,
                        label: 'Best Streak',
                        value: '$best',
                        scale: scale,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10 * scale),
                Text(
                  'Discipline today, stronger tomorrow.',
                  style: AppTypography.label.copyWith(
                    fontSize: 9 * scale,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
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

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.scale,
  });

  final IconData icon;
  final String label;
  final String value;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.amber, size: 16 * scale),
        SizedBox(height: 4 * scale),
        Text(
          value,
          style: AppTypography.metric.copyWith(
            fontSize: 18 * scale,
            color: AppColors.white,
          ),
        ),
        Text(
          label,
          style: AppTypography.label.copyWith(fontSize: 7.5 * scale),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _DailySponsorsStrip extends StatelessWidget {
  const _DailySponsorsStrip({required this.sponsors, required this.scale});

  final List<ShareSponsor> sponsors;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
        color: AppColors.charcoal.withValues(alpha: 0.65),
      ),
      child: Column(
        children: [
          Text(
            'POWERED BY',
            style: AppTypography.label.copyWith(
              color: AppColors.amber,
              fontSize: 7 * scale,
            ),
          ),
          SizedBox(height: 4 * scale),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final s in sponsors.take(3)) ...[
                Flexible(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 18 * scale,
                        child: SponsorLogo(
                          urlOrPath: s.logoUrl,
                          fallbackIconSize: 14 * scale,
                        ),
                      ),
                      Text(
                        s.name,
                        style: AppTypography.label.copyWith(
                          fontSize: 7 * scale,
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
            ],
          ),
        ],
      ),
    );
  }
}
