import 'dart:math';

import 'package:flutter/material.dart';

import '../../features/gyms/models/gym.dart';
import '../theme/app_theme.dart';
import '../utils/geo.dart';

class GymMap extends StatefulWidget {
  const GymMap({
    super.key,
    required this.gyms,
    required this.user,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Gym> gyms;
  final GeoPoint user;
  final String? selectedId;
  final ValueChanged<Gym> onSelect;

  @override
  State<GymMap> createState() => _GymMapState();
}

class _GymMapState extends State<GymMap> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onTapUp: (details) {
            final nearest = _hitTest(details.localPosition, size);
            if (nearest != null) widget.onSelect(nearest);
          },
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              return CustomPaint(
                size: size,
                painter: DummyMapPainter(
                  gyms: widget.gyms,
                  user: widget.user,
                  selectedId: widget.selectedId,
                  pulse: _pulse.value,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Gym? _hitTest(Offset tap, Size size) {
    Gym? best;
    var bestDist = 28.0;
    for (final gym in widget.gyms) {
      final p = DummyMapPainter.project(gym.location, size);
      final d = (p - tap).distance;
      if (d < bestDist) {
        bestDist = d;
        best = gym;
      }
    }
    return best;
  }
}

class DummyMapPainter extends CustomPainter {
  DummyMapPainter({
    required this.gyms,
    required this.user,
    required this.selectedId,
    this.pulse = 0,
  });

  final List<Gym> gyms;
  final GeoPoint user;
  final String? selectedId;
  final double pulse;

  static const _south = 31.455;
  static const _north = 31.480;
  static const _west = 76.255;
  static const _east = 76.282;

  static Offset project(GeoPoint point, Size size) {
    final x = (point.longitude - _west) / (_east - _west);
    final y = 1 - (point.latitude - _south) / (_north - _south);
    return Offset(x * size.width, y * size.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = AppColors.backgroundElevated;
    canvas.drawRect(Offset.zero & size, bg);

    final grid = Paint()
      ..color = AppColors.borderSubtle
      ..strokeWidth = 1;
    const step = 28.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final block = Paint()..color = AppColors.backgroundElevated;
    final blockBorder = Paint()
      ..color = AppColors.charcoal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rng = Random(7);
    for (var i = 0; i < 18; i++) {
      final left = rng.nextDouble() * (size.width - 70);
      final top = rng.nextDouble() * (size.height - 50);
      final rect = Rect.fromLTWH(left, top, 46 + rng.nextDouble() * 40, 28 + rng.nextDouble() * 26);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), block);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), blockBorder);
    }

    final road = Paint()
      ..color = AppColors.charcoal
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final roadInner = Paint()
      ..color = AppColors.surface
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final roads = [
      Path()
        ..moveTo(0, size.height * 0.35)
        ..quadraticBezierTo(size.width * 0.4, size.height * 0.28, size.width, size.height * 0.4),
      Path()
        ..moveTo(size.width * 0.22, 0)
        ..quadraticBezierTo(size.width * 0.28, size.height * 0.5, size.width * 0.18, size.height),
      Path()
        ..moveTo(0, size.height * 0.72)
        ..quadraticBezierTo(size.width * 0.55, size.height * 0.78, size.width, size.height * 0.62),
    ];
    for (final path in roads) {
      canvas.drawPath(path, road);
      canvas.drawPath(path, roadInner);
    }

    for (final gym in gyms) {
      final p = project(gym.location, size);
      final selected = gym.id == selectedId;
      if (selected) {
        final zoneR = 18 + pulse * 10;
        final zone = Paint()
          ..color = AppColors.amber.withValues(alpha: 0.16 * (1 - pulse))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(p, zoneR, zone);
        canvas.drawCircle(
          p,
          22,
          Paint()
            ..color = AppColors.amber.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
      canvas.drawCircle(p, selected ? 8 : 6, Paint()..color = AppColors.amber);
      canvas.drawCircle(p, selected ? 8 : 6, Paint()
        ..color = AppColors.background
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
    }

    final userP = project(user, size);
    canvas.drawCircle(userP, 14, Paint()..color = AppColors.white.withValues(alpha: 0.12));
    canvas.drawCircle(userP, 6, Paint()..color = AppColors.white);
    canvas.drawCircle(
      userP,
      6,
      Paint()
        ..color = AppColors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant DummyMapPainter oldDelegate) {
    return oldDelegate.selectedId != selectedId ||
        oldDelegate.user != user ||
        oldDelegate.pulse != pulse ||
        oldDelegate.gyms != gyms;
  }
}
