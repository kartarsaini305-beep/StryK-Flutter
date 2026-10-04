import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../features/share/models/share_payload.dart';
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
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = (constraints.maxWidth / 320).clamp(0.72, 1.15);
          return switch (style) {
            ShareCardStyle.minimal =>
              _MinimalCard(payload: payload, scale: scale),
            ShareCardStyle.photo => _PhotoCard(payload: payload, scale: scale),
            ShareCardStyle.achievement =>
              _AchievementCard(payload: payload, scale: scale),
          };
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
    return ColoredBox(
      color: const Color(0xFF0E0E0E),
      child: Padding(
        padding: EdgeInsets.fromLTRB(pad, pad, pad, pad * 0.85),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StrykLogo(height: 18 * scale, light: true),
                const Spacer(),
                Flexible(
                  child: Text(
                    'BUILD BETTER HABITS',
                    style: AppTypography.label.copyWith(
                      fontSize: 8.5 * scale,
                      letterSpacing: 1.2,
                      color: AppColors.textMuted,
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
      ),
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
                      StrykLogo(height: 16 * scale, light: true),
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
                          'JUST SHOWED UP.',
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border.all(
          color: AppColors.amber.withValues(alpha: 0.55),
          width: 1.4,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _GrainPainter(alpha: 0.07)),
          Padding(
            padding: EdgeInsets.fromLTRB(
              18 * scale,
              18 * scale,
              18 * scale,
              14 * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StrykLogo(height: 16 * scale, light: true),
                SizedBox(height: 8 * scale),
                Text(
                  'DAY ${payload.dayNumber}',
                  style: AppTypography.label.copyWith(
                    letterSpacing: 2.2,
                    fontSize: 11 * scale,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Transform.rotate(
                    angle: -0.04,
                    child: Text(
                      'JUST\nSHOWED\nUP.',
                      style: AppTypography.display.copyWith(
                        fontSize: 44 * scale,
                        height: 0.92,
                        fontStyle: FontStyle.italic,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 14 * scale),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.rotate(
                    angle: -0.02,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12 * scale,
                        vertical: 8 * scale,
                      ),
                      color: AppColors.amber,
                      child: Text(
                        Dates.sessionDurationLabel(payload.duration),
                        style: AppTypography.subheading.copyWith(
                          color: AppColors.textOnLight,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          fontSize: 14 * scale,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  payload.gymName.toUpperCase(),
                  style: AppTypography.subheading.copyWith(fontSize: 13 * scale),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${Dates.upperDay(payload.date)}  ·  ${Dates.timeRange(payload.startTime, payload.endTime)}',
                  style: AppTypography.body.copyWith(fontSize: 11 * scale),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4 * scale),
                Text(
                  'STRYK ${payload.dayNumber}',
                  style: AppTypography.label.copyWith(
                    color: AppColors.amber,
                    fontSize: 11 * scale,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6 * scale),
                Row(
                  children: [
                    Expanded(child: _VerifyMark(payload: payload, compact: true)),
                    SizedBox(width: 8 * scale),
                    Text(
                      'SAME YOU.\nSTRONGER TOMORROW.',
                      textAlign: TextAlign.right,
                      style: AppTypography.label.copyWith(
                        fontSize: 7.5 * scale,
                        fontStyle: FontStyle.italic,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({this.alpha = 0.08});

  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(21);
    final paint = Paint()..color = Color.fromRGBO(255, 255, 255, alpha);
    for (var i = 0; i < 380; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        random.nextDouble() * 1.1,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
