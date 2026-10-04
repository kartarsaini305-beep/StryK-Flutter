import '../../gyms/models/gym.dart';
import '../../session/models/gym_session.dart';
import '../models/daily_record.dart';
import '../models/streak_protection.dart';
import '../models/streak_snapshot.dart';

class StreakUpdate {
  const StreakUpdate({
    required this.streak,
    required this.records,
    required this.protection,
  });

  final StreakSnapshot streak;
  final Map<String, DailyRecord> records;
  final StreakProtection protection;
}

abstract class StreakService {
  StreakUpdate completeSession({
    required DateTime now,
    required Gym gym,
    required GymSession session,
    required StreakSnapshot streak,
    required Map<String, DailyRecord> records,
    required StreakProtection protection,
  });
}
