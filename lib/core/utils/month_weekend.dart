/// Last-weekend helpers for monthly share gating.
abstract final class MonthWeekend {
  /// True on the last Saturday / Sunday of [at]'s calendar month.
  static bool isLastWeekendOfMonth([DateTime? at]) {
    final now = at ?? DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final last = DateTime(now.year, now.month + 1, 0);
    // Walk back to last Sunday of the month.
    var sunday = last;
    while (sunday.weekday != DateTime.sunday) {
      sunday = sunday.subtract(const Duration(days: 1));
    }
    final saturday = sunday.subtract(const Duration(days: 1));
    return !day.isBefore(saturday) && !day.isAfter(sunday);
  }

  /// Label for UI copy.
  static String windowLabel([DateTime? at]) {
    final now = at ?? DateTime.now();
    final last = DateTime(now.year, now.month + 1, 0);
    var sunday = last;
    while (sunday.weekday != DateTime.sunday) {
      sunday = sunday.subtract(const Duration(days: 1));
    }
    final saturday = sunday.subtract(const Duration(days: 1));
    String fmt(DateTime d) => '${_months[d.month - 1]} ${d.day}';
    return '${fmt(saturday)} – ${fmt(sunday)}';
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}
