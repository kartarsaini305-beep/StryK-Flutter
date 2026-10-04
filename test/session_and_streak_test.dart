import 'package:flutter_test/flutter_test.dart';
import 'package:stryk/app/config.dart';
import 'package:stryk/core/theme/intensity_colors.dart';
import 'package:stryk/core/utils/geo.dart';
import 'package:stryk/core/utils/session_clock.dart';
import 'package:stryk/features/admin/models/admin_config.dart';
import 'package:stryk/features/gyms/models/gym.dart';
import 'package:stryk/features/session/models/gym_session.dart';
import 'package:stryk/features/share/models/share_payload.dart';
import 'package:stryk/features/streak/models/daily_record.dart';
import 'package:stryk/features/streak/models/streak_protection.dart';
import 'package:stryk/features/streak/models/streak_snapshot.dart';
import 'package:stryk/services/mock_gym_service.dart';
import 'package:stryk/services/mock_streak_service.dart';
import 'package:stryk/services/mock_verification_service.dart';

void main() {
  final gym = MockGymService.gyms.first;

  test('remaining time uses timestamps, not a decrementing integer', () {
    final start = DateTime(2026, 4, 1, 7, 0);
    final now = start.add(const Duration(minutes: 2, seconds: 18));
    final session = GymSession(
      gymId: gym.id,
      status: SessionStatus.tracking,
      startTime: start,
    );
    final elapsed = session.elapsed(now);
    final remaining = AppConfig.sessionDuration - elapsed;
    expect(elapsed, const Duration(minutes: 2, seconds: 18));
    expect(remaining, const Duration(minutes: 17, seconds: 42));
  });

  test('completing twice on the same day awards one gym day', () {
    final service = MockStreakService();
    final now = DateTime(2026, 4, 1, 19, 18);
    final session = GymSession(
      gymId: gym.id,
      status: SessionStatus.completed,
      startTime: now.subtract(const Duration(minutes: 20)),
      endTime: now,
    );

    final first = service.completeSession(
      now: now,
      gym: gym,
      session: session,
      streak: const StreakSnapshot(),
      records: {},
      protection: const StreakProtection(),
    );
    final second = service.completeSession(
      now: now.add(const Duration(minutes: 5)),
      gym: gym,
      session: session,
      streak: first.streak,
      records: first.records,
      protection: first.protection,
    );

    expect(first.streak.totalGymDays, 1);
    expect(first.streak.current, 1);
    expect(second.streak.totalGymDays, 1);
    expect(second.records.length, 1);
  });

  test('dummy gyms include Iron House Gym', () {
    expect(
      MockGymService.gyms.map((Gym g) => g.name),
      contains('Iron House Gym'),
    );
    expect(
      const GeoPoint(31.4689, 76.2708).distanceTo(gym.location),
      lessThan(1),
    );
  });

  test('share payload uses the selected historical record, not a hardcoded day', () {
    final verification = MockVerificationService();
    final older = verification.stamp(
      DailyRecord(
        dateKey: '2025-04-14',
        kind: DayKind.completed,
        gymName: 'Iron House Gym',
        arrivalTime: DateTime(2025, 4, 14, 15, 4),
        endTime: DateTime(2025, 4, 14, 16, 17),
        duration: const Duration(hours: 1, minutes: 13),
        streakAtPoint: 14,
        totalGymDaysAtThatTime: 14,
      ),
    );
    final payload = SharePayload.fromRecord(older);
    expect(payload.dayNumber, 14);
    expect(payload.gymName, 'Iron House Gym');
    expect(payload.duration, const Duration(hours: 1, minutes: 13));
    expect(payload.endTime.difference(payload.startTime), payload.duration);
    expect(payload.verificationId, startsWith('SK-'));
    expect(payload.verificationUrl, contains(payload.verificationId));
    expect(ShareCardStyleX.parse('cinema'), ShareCardStyle.minimal);
  });

  test('demo time mode maps 1 real second to 1 simulated minute', () {
    final start = DateTime(2026, 4, 1, 15, 0);
    final wall = start.add(const Duration(seconds: 25));
    final elapsed = SessionClock.elapsed(
      wallNow: wall,
      config: const AdminConfig(demoTimeMode: true),
      sessionStart: start,
    );
    expect(elapsed, const Duration(minutes: 25));
  });

  test('calendar intensity bands follow duration thresholds', () {
    expect(
      IntensityColors.calendarIntensity(const Duration(minutes: 19)),
      isNot(IntensityColors.light),
    );
    expect(
      IntensityColors.calendarIntensity(const Duration(minutes: 25)),
      IntensityColors.light,
    );
    expect(
      IntensityColors.calendarIntensity(const Duration(minutes: 40)),
      IntensityColors.medium,
    );
    expect(
      IntensityColors.calendarIntensity(const Duration(minutes: 55)),
      IntensityColors.dark,
    );
  });

  test('session secured status keeps timer active until checkout', () {
    final start = DateTime(2026, 4, 1, 15, 4);
    final now = start.add(const Duration(hours: 1, minutes: 13));
    final session = GymSession(
      gymId: gym.id,
      status: SessionStatus.secured,
      startTime: start,
      securedAt: start.add(const Duration(minutes: 20)),
      endTime: now,
    );
    expect(session.isActive, isTrue);
    expect(session.isCheckedOut, isFalse);
    expect(session.elapsed(now), const Duration(hours: 1, minutes: 13));
  });
}
