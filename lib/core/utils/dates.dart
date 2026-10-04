import 'package:intl/intl.dart';

abstract final class Dates {
  static final yMd = DateFormat('yyyy-MM-dd');
  static final long = DateFormat('EEEE, d MMMM y');
  static final short = DateFormat('d MMM y');
  static final time = DateFormat('h:mm a');
  static final weekDay = DateFormat('E');
  static final dayStamp = DateFormat('d MMM y');
  static final dayStampShort = DateFormat('d MMM');

  static String key(DateTime date) => yMd.format(calendarDay(date));

  static String upperDay(DateTime date) =>
      DateFormat('d MMM y').format(date).toUpperCase();

  static String minutesLabel(Duration duration) {
    final minutes = duration.inMinutes.clamp(1, 24 * 60);
    return '$minutes MIN';
  }

  static DateTime calendarDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isSunday(DateTime date) => date.weekday == DateTime.sunday;

  static String formatDuration(Duration duration) {
    final total = duration.inSeconds.clamp(0, 24 * 3600);
    final m = total ~/ 60;
    final s = total % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String compactDuration(Duration duration) {
    return friendlyDuration(duration).toUpperCase();
  }

  /// Human duration like `20m` or `1h 13m`.
  static String friendlyDuration(Duration duration) {
    final totalMinutes = duration.inMinutes.clamp(0, 24 * 60);
    if (totalMinutes < 60) return '${totalMinutes.clamp(1, 59)}m';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  static String sessionDurationLabel(Duration duration) {
    return '${friendlyDuration(duration).toUpperCase()} SESSION';
  }

  static String timeRange(DateTime start, DateTime end) {
    return '${time.format(start)} → ${time.format(end)}';
  }
}
