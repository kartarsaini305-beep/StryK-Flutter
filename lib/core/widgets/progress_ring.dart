import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 220,
    this.stroke = 10,
    this.color = AppColors.amber,
    this.trackColor = AppColors.charcoal,
    this.glow = true,
  });

  final double progress;
  final Widget child;
  final double size;
  final double stroke;
  final Color color;
  final Color trackColor;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final side = size.clamp(96.0, 280.0);
    return SizedBox(
      width: side,
      height: side,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (glow)
            Container(
              width: side * 0.92,
              height: side * 0.92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: side * 0.22,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          TweenAnimationBuilder<double>(
            tween: Tween(end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return CustomPaint(
                size: Size.square(side),
                painter: _RingPainter(
                  progress: value,
                  stroke: stroke,
                  track: trackColor,
                  fill: color,
                ),
              );
            },
          ),
          Padding(
            padding: EdgeInsets.all(stroke + 8),
            child: child,
          ),
        ],
      ),
    );
  }
}

class StreakRing extends StatelessWidget {
  const StreakRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 210,
  });

  final double progress;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ProgressRing(progress: progress, size: size, child: child);
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.stroke,
    required this.track,
    required this.fill,
  });

  final double progress;
  final double stroke;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: pi * 1.5,
        colors: [
          fill.withValues(alpha: 0.55),
          fill,
          AppColors.gold,
        ],
        stops: const [0.0, 0.55, 1.0],
        transform: const GradientRotation(-pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, pi * 2, false, trackPaint);
    canvas.drawArc(rect, -pi / 2, pi * 2 * progress, false, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.fill != fill;
  }
}
