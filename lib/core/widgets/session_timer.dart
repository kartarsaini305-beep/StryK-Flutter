import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/intensity_colors.dart';
import '../../core/utils/dates.dart';
import '../../features/session/models/gym_session.dart';
import '../../providers/app_controller.dart';
import '../theme/app_theme.dart';
import 'progress_ring.dart';

class SessionTimer extends ConsumerWidget {
  const SessionTimer({super.key});

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
    // Fill toward min stay, then keep rising gently past 100%.
    final progress = secured
        ? (0.7 + (elapsed.inMinutes / 90).clamp(0, 0.3)).clamp(0.7, 1.0)
        : (elapsed.inMilliseconds / minStay.inMilliseconds).clamp(0.0, 1.0);

    final maxSide = MediaQuery.sizeOf(context).width * 0.58;

    return Column(
      children: [
        TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: color),
          duration: const Duration(milliseconds: 450),
          builder: (context, animatedColor, child) {
            final ringColor = animatedColor ?? color;
            return ProgressRing(
              size: maxSide,
              progress: progress,
              color: ringColor,
              stroke: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      Dates.friendlyDuration(elapsed),
                      style: AppTypography.display.copyWith(
                        fontSize: 40,
                        color: ringColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    secured ? 'SESSION VALID' : 'elapsed',
                    style: AppTypography.label.copyWith(
                      letterSpacing: 1.2,
                      color: secured ? AppColors.success : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        if (start != null)
          Text(
            'Started ${Dates.time.format(start)}',
            style: AppTypography.body,
          ),
        Text(
          secured
              ? 'Streak secured. Timer keeps running.'
              : '${remaining.inMinutes.clamp(0, 999)} min to secure today’s streak',
          style: AppTypography.bodyMedium.copyWith(
            color: secured ? AppColors.success : color,
          ),
          textAlign: TextAlign.center,
        ),
        if (state.adminConfig.demoTimeMode) ...[
          const SizedBox(height: 6),
          Text(
            'DEMO TIME · 1s = 1m',
            style: AppTypography.label.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}
