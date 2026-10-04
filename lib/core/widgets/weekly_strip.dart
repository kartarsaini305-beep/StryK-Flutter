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
    Color fill = AppColors.charcoal;
    Color text = AppColors.textMuted;
    var label = Dates.weekDay.format(day).substring(0, 1);
    if (record?.kind == DayKind.completed) {
      fill = AppColors.amber;
      text = AppColors.textOnLight;
    } else if (record?.kind == DayKind.sundayProtected ||
        record?.kind == DayKind.streakSaved) {
      fill = AppColors.protected;
      text = AppColors.textOnLight;
    } else if (record?.kind == DayKind.missed) {
      fill = AppColors.charcoalDeep;
    }
    if (future) {
      fill = Colors.transparent;
      text = AppColors.textMuted;
    }

    return Semantics(
      button: onTap != null && !future,
      label: '${Dates.weekDay.format(day)} ${record?.kind.name ?? 'no activity'}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: GestureDetector(
          onTap: future ? null : () => onTap?.call(day),
          child: Column(
            children: [
              Text(label, style: AppTypography.label.copyWith(fontSize: 11)),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                height: 36,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(10),
                  border: today
                      ? Border.all(color: AppColors.white.withValues(alpha: 0.35))
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: AppTypography.bodyMedium.copyWith(color: text, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
