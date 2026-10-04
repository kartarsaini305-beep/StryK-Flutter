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
  });

  final double progress;
  final Widget child;
  final double size;
  final double stroke;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final side = size.clamp(120.0, 260.0);
    return SizedBox(
      width: side,
      height: side,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(side),
            painter: _RingPainter(
              progress: progress.clamp(0.0, 1.0),
              stroke: stroke,
              track: trackColor,
              fill: color,
            ),
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
      ..color = fill
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
