import '../core/utils/dates.dart';
import '../features/gyms/models/gym.dart';
import '../features/session/models/gym_session.dart';
import '../features/streak/models/daily_record.dart';
import '../features/streak/models/streak_protection.dart';
import '../features/streak/models/streak_snapshot.dart';
import '../features/streak/services/streak_service.dart';

class MockStreakService implements StreakService {
  @override
  StreakUpdate completeSession({
    required DateTime now,
    required Gym gym,
    required GymSession session,
    required StreakSnapshot streak,
    required Map<String, DailyRecord> records,
    required StreakProtection protection,
  }) {
    final key = Dates.key(now);
    final existing = records[key];
    if (existing?.isCompleted == true) {
      return StreakUpdate(
        streak: streak,
        records: records,
        protection: protection,
      );
    }

    var workingProtection = protection;
    var nextCurrent = 1;
    final lastCompleted = _lastCompleted(records, before: now);
    if (lastCompleted != null) {
      final gap = _missedDays(after: lastCompleted, before: Dates.calendarDay(now));
      var broken = false;
      for (final day in gap) {
        if (Dates.isSunday(day)) {
          records[Dates.key(day)] = DailyRecord(
            dateKey: Dates.key(day),
            kind: DayKind.sundayProtected,
            wasSundayProtected: true,
          );
          continue;
        }
        if (workingProtection.bankedSaves > 0) {
          workingProtection = workingProtection.copyWith(bankedSaves: 0);
          records[Dates.key(day)] = DailyRecord(
            dateKey: Dates.key(day),
            kind: DayKind.streakSaved,
            wasStreakSaved: true,
          );
          continue;
        }
        broken = true;
        records[Dates.key(day)] = DailyRecord(
          dateKey: Dates.key(day),
          kind: DayKind.missed,
        );
        break;
      }
      nextCurrent = broken ? 1 : streak.current + 1;
    }

    final nextTotal = streak.totalGymDays + 1;
    if (nextTotal >= workingProtection.lastSaveEarnedAtTotal + 10 &&
        workingProtection.bankedSaves == 0) {
      workingProtection = workingProtection.copyWith(
        bankedSaves: 1,
        lastSaveEarnedAtTotal: nextTotal,
      );
    }

    final next = StreakSnapshot(
      current: nextCurrent,
      best: nextCurrent > streak.best ? nextCurrent : streak.best,
      totalGymDays: nextTotal,
    );

    records[key] = DailyRecord(
      dateKey: key,
      kind: DayKind.completed,
      gymId: gym.id,
      gymName: gym.name,
      arrivalTime: session.startTime ?? now,
      endTime: session.endTime ?? now,
      duration: session.elapsed(now),
      streakAtPoint: next.current,
      totalGymDaysAtThatTime: next.totalGymDays,
    );

    return StreakUpdate(
      streak: next,
      records: Map<String, DailyRecord>.from(records),
      protection: workingProtection,
    );
  }

  DateTime? _lastCompleted(Map<String, DailyRecord> records, {required DateTime before}) {
    final completed = records.values.where((r) => r.isCompleted).toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    for (final record in completed) {
      final date = DateTime.parse(record.dateKey);
      if (date.isBefore(Dates.calendarDay(before))) return date;
    }
    return null;
  }

  List<DateTime> _missedDays({required DateTime after, required DateTime before}) {
    final days = <DateTime>[];
    var cursor = after.add(const Duration(days: 1));
    while (cursor.isBefore(before)) {
      days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return days;
  }
}
