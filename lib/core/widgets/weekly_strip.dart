import 'package:flutter/material.dart';

import '../../features/streak/models/daily_record.dart';
import '../../features/streak/services/history_query.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';

class WeeklyStrip extends StatelessWidget {
  const WeeklyStrip({super.key, required this.records, this.onDayTap});

  final Map<String, DailyRecord> records;
  final ValueChanged<DateTime>? onDayTap;

  @override
  Widget build(BuildContext context) {
    final days = HistoryQuery.currentWeek(DateTime.now());
    return Row(
      children: [
        for (final day in days)
          Expanded(
            child: _DayCell(
              day: day,
              record: records[Dates.key(day)],
              onTap: onDayTap,
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.record, this.onTap});

  final DateTime day;
  final DailyRecord? record;
  final ValueChanged<DateTime>? onTap;

  @override
  Widget build(BuildContext context) {
    final today = Dates.isSameDay(day, DateTime.now());
    final future = day.isAfter(Dates.calendarDay(DateTime.now()));
    final completed = record?.kind == DayKind.completed;
    final protected = record?.kind == DayKind.sundayProtected ||
        record?.kind == DayKind.streakSaved;
    final missed = record?.kind == DayKind.missed;

    Color fill = AppColors.charcoal;
    Color text = AppColors.textMuted;
    if (completed) {
      fill = AppColors.amber;
      text = AppColors.textOnLight;
    } else if (protected) {
      fill = AppColors.protected;
      text = AppColors.textOnLight;
    } else if (missed) {
      fill = AppColors.charcoalDeep;
    }
    if (future) {
      fill = Colors.transparent;
      text = AppColors.textMuted.withValues(alpha: 0.45);
    }

    return Semantics(
      button: onTap != null && !future,
      label:
          '${Dates.weekDay.format(day)} ${record?.kind.name ?? 'no activity'}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: GestureDetector(
          onTap: future ? null : () => onTap?.call(day),
          child: Column(
            children: [
              Text(
                Dates.weekDay.format(day).substring(0, 1),
                style: AppTypography.label.copyWith(fontSize: 10),
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                height: 38,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(11),
                  border: today
                      ? Border.all(
                          color: completed
                              ? AppColors.white.withValues(alpha: 0.55)
                              : AppColors.amber,
                          width: 1.4,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: text,
                    fontSize: 13,
                    fontVariations: [
                      FontVariation('wght', today || completed ? 700 : 500),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
