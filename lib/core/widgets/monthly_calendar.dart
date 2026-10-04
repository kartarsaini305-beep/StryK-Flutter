import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/streak/models/daily_record.dart';
import '../theme/app_theme.dart';
import '../theme/intensity_colors.dart';
import '../utils/dates.dart';

/// Monthly activity calendar with duration-based intensity colors.
class MonthlyCalendar extends StatefulWidget {
  const MonthlyCalendar({
    super.key,
    required this.records,
    required this.onDayTap,
    this.minStay = const Duration(minutes: 20),
  });

  final Map<String, DailyRecord> records;
  final ValueChanged<DateTime> onDayTap;
  final Duration minStay;

  @override
  State<MonthlyCalendar> createState() => _MonthlyCalendarState();
}

class _MonthlyCalendarState extends State<MonthlyCalendar> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shift(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = Dates.calendarDay(DateTime.now());
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // Monday-first grid: weekday 1=Mon … 7=Sun
    final leading = first.weekday - 1;
    final totalCells = leading + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Semantics(
      label: 'Monthly gym activity calendar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: () => _shift(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(_month),
                  style: AppTypography.subheading,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: () => _shift(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: const [
              _Dow('M'),
              _Dow('T'),
              _Dow('W'),
              _Dow('T'),
              _Dow('F'),
              _Dow('S'),
              _Dow('S'),
            ],
          ),
          const SizedBox(height: 6),
          for (var row = 0; row < rows; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: List.generate(7, (col) {
                  final index = row * 7 + col;
                  final dayNum = index - leading + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 36));
                  }
                  final day = DateTime(_month.year, _month.month, dayNum);
                  final record = widget.records[Dates.key(day)];
                  final isFuture = day.isAfter(today);
                  final isToday = Dates.isSameDay(day, today);
                  final color = _cellColor(record, isFuture);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Material(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: isFuture ? null : () => widget.onDayTap(day),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: isToday
                                    ? Border.all(color: AppColors.amber, width: 1.4)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '$dayNum',
                                  style: AppTypography.label.copyWith(
                                    color: isFuture
                                        ? AppColors.textMuted.withValues(alpha: 0.4)
                                        : AppColors.textPrimary,
                                    fontWeight:
                                        isToday ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Intensity', style: AppTypography.label),
              _legend(IntensityColors.light, '20–30m'),
              _legend(IntensityColors.medium, '30–50m'),
              _legend(IntensityColors.dark, '50m+'),
            ],
          ),
        ],
      ),
    );
  }

  Color _cellColor(DailyRecord? record, bool isFuture) {
    if (isFuture) return Colors.transparent;
    if (record == null) return AppColors.charcoal;
    switch (record.kind) {
      case DayKind.sundayProtected:
      case DayKind.streakSaved:
        return AppColors.protected.withValues(alpha: 0.55);
      case DayKind.missed:
        return AppColors.charcoalDeep;
      case DayKind.completed:
        return IntensityColors.calendarIntensity(
          record.duration,
          minStay: widget.minStay,
        );
      case DayKind.none:
        return AppColors.charcoal;
    }
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.label),
      ],
    );
  }
}

class _Dow extends StatelessWidget {
  const _Dow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: AppTypography.label.copyWith(fontSize: 11),
        ),
      ),
    );
  }
}
