import '../models/daily_record.dart';

class HistoryQuery {
  const HistoryQuery._();

  static List<DailyRecord> newestFirst(Map<String, DailyRecord> records) {
    final items = records.values
        .where((record) => record.kind != DayKind.none)
        .toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return items;
  }

  static List<DateTime> currentWeek(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }
}
