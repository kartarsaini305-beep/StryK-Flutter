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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: Column(
              key: ValueKey('${_month.year}-${_month.month}'),
              children: [
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
                                  onTap:
                                      isFuture ? null : () => widget.onDayTap(day),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: isToday
                                          ? Border.all(
                                              color: AppColors.amber,
                                              width: 1.4,
                                            )
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$dayNum',
                                        style: AppTypography.label.copyWith(
                                          color: isFuture
                                              ? AppColors.textMuted
                                                  .withValues(alpha: 0.4)
                                              : AppColors.textPrimary,
                                          fontWeight: isToday
                                              ? FontWeight.w700
                                              : FontWeight.w500,
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
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('INTENSITY', style: AppTypography.label.copyWith(fontSize: 10)),
              _legend(IntensityColors.light, 'Light'),
              _legend(IntensityColors.medium, 'Medium'),
              _legend(IntensityColors.dark, 'Intense'),
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
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.borderSubtle),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTypography.label.copyWith(fontSize: 11)),
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
