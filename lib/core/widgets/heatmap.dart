import 'package:flutter/material.dart';

import '../../features/streak/models/daily_record.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';

class Heatmap extends StatelessWidget {
  const Heatmap({
    super.key,
    required this.records,
    required this.onDayTap,
    this.weeks = 12,
  });

  final Map<String, DailyRecord> records;
  final ValueChanged<DateTime> onDayTap;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final today = Dates.calendarDay(DateTime.now());
    final start = today.subtract(Duration(days: weeks * 7 - 1));
    final alignedStart = start.subtract(Duration(days: start.weekday % 7));

    return Semantics(
      label: '12-week gym activity heatmap',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(weeks, (week) {
              return Expanded(
                child: Column(
                  children: List.generate(7, (weekday) {
                    final day = alignedStart.add(Duration(days: week * 7 + weekday));
                    final inRange = !day.isBefore(start) && !day.isAfter(today);
                    final record = records[Dates.key(day)];
                    final color = !inRange
                        ? Colors.transparent
                        : record?.kind == DayKind.completed
                            ? AppColors.amber
                        : record?.kind == DayKind.sundayProtected
                            ? AppColors.protected.withValues(alpha: 0.7)
                            : record?.kind == DayKind.streakSaved
                                ? AppColors.protected
                                : record?.kind == DayKind.missed
                                    ? AppColors.charcoalDeep
                                    : AppColors.charcoal;
                    final status = !inRange
                        ? 'outside range'
                        : record?.kind == DayKind.completed
                            ? 'completed'
                            : record?.kind == DayKind.sundayProtected
                                ? 'Sunday safe'
                                : record?.kind == DayKind.streakSaved
                                    ? 'streak saved'
                                    : record?.kind == DayKind.missed
                                        ? 'missed'
                                        : 'no activity';
                    return Padding(
                      padding: const EdgeInsets.all(2),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Semantics(
                          button: inRange,
                          label: '${Dates.short.format(day)}, $status',
                          child: InkWell(
                            onTap: inRange ? () => onDayTap(day) : null,
                            borderRadius: BorderRadius.circular(3),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text('Less', style: AppTypography.label),
              const SizedBox(width: 8),
              _swatch(AppColors.charcoal),
              const SizedBox(width: 4),
              _swatch(AppColors.protected),
              const SizedBox(width: 4),
              _swatch(AppColors.amber),
              const SizedBox(width: 8),
              Text('More', style: AppTypography.label),
            ],
          ),
        ],
      ),
    );
  }

  Widget _swatch(Color color) {
    return SizedBox(
      width: 12,
      height: 12,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
