import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/intensity_colors.dart';
import '../../core/utils/dates.dart';
import '../../features/session/models/gym_session.dart';
import '../../providers/app_controller.dart';
import '../theme/app_theme.dart';
import 'progress_ring.dart';

class SessionTimer extends ConsumerWidget {
  const SessionTimer({
    super.key,
    this.compact = false,
    this.showMeter = true,
    this.showCaption = true,
  });

  final bool compact;
  final bool showMeter;
  final bool showCaption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(tickerProvider);
    final wall = DateTime.now();
    final state = ref.watch(appControllerProvider);
    final elapsed = state.elapsed(wall);
    final remaining = state.remaining(wall);
    final minStay = state.minStay;
    final secured = state.session?.status == SessionStatus.secured ||
        state.session?.status == SessionStatus.completed ||
        remaining == Duration.zero;
    final start = state.session?.startTime;
    final color = IntensityColors.timerColor(elapsed);
    final progress = secured
        ? (0.7 + (elapsed.inMinutes / 90).clamp(0, 0.3)).clamp(0.7, 1.0)
        : (elapsed.inMilliseconds / minStay.inMilliseconds).clamp(0.0, 1.0);

    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    final maxSide = compact
        ? (width * 0.30).clamp(100.0, 140.0)
        : (width * 0.58).clamp(180.0, height < 700 ? 210.0 : 248.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProgressRing(
          size: maxSide,
          progress: progress,
          color: secured ? AppColors.amber : color,
          stroke: compact ? 9 : 12,
          trackColor: AppColors.charcoalDeep,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  Dates.formatDuration(elapsed),
                  style: AppTypography.display.copyWith(
                    fontSize: compact ? 22 : 38,
                    letterSpacing: -1,
                    color: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                secured ? 'STREAK SECURED' : 'LIVE',
                style: AppTypography.label.copyWith(
                  letterSpacing: 1.2,
                  fontSize: compact ? 8 : 10,
                  color: secured ? AppColors.amber : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (showMeter) ...[
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppColors.charcoal,
              color: secured ? AppColors.amber : color,
            ),
          ),
        ],
        if (showCaption) ...[
          const SizedBox(height: 10),
          if (start != null)
            Text(
              'Started ${Dates.time.format(start)} · Min stay ${minStay.inMinutes}m',
              style: AppTypography.body.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 280),
            style: AppTypography.bodyMedium.copyWith(
              color: secured ? AppColors.amber : color,
              fontSize: 13,
            ),
            child: Text(
              secured
                  ? 'Streak secured. Timer keeps running until checkout.'
                  : '${remaining.inMinutes.clamp(0, 999)} min to secure today’s streak',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (state.adminConfig.demoTimeMode) ...[
            const SizedBox(height: 4),
            Text(
              'DEMO TIME · 1s = 1m',
              style: AppTypography.label.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ],
    );
  }
}
