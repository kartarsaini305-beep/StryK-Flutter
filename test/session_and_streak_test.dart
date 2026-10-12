import 'package:flutter_test/flutter_test.dart';
import 'package:stryk/app/config.dart';
import 'package:stryk/core/theme/intensity_colors.dart';
import 'package:stryk/core/utils/geo.dart';
import 'package:stryk/core/utils/session_clock.dart';
import 'package:stryk/features/admin/models/admin_config.dart';
import 'package:stryk/features/gyms/models/gym.dart';
import 'package:stryk/features/profile/models/app_settings.dart';
import 'package:stryk/features/session/models/gym_session.dart';
import 'package:stryk/features/session/models/location_snapshot.dart';
import 'package:stryk/features/share/models/share_payload.dart';
import 'package:stryk/features/streak/models/daily_record.dart';
import 'package:stryk/features/streak/models/streak_protection.dart';
import 'package:stryk/features/streak/models/streak_snapshot.dart';
import 'package:stryk/providers/app_state.dart';
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

  test('session photo is shared by payload for every card template', () {
    final record = DailyRecord(
      dateKey: '2026-04-01',
      kind: DayKind.completed,
      gymName: 'Iron House Gym',
      arrivalTime: DateTime(2026, 4, 1, 15, 4),
      endTime: DateTime(2026, 4, 1, 16, 17),
      duration: const Duration(hours: 1, minutes: 13),
      streakAtPoint: 12,
      optionalPhotoPath: '/tmp/session-photo.jpg',
    );
    final payload = SharePayload.fromRecord(record);
    expect(record.sessionPhotoPath, '/tmp/session-photo.jpg');
    expect(payload.photoPath, '/tmp/session-photo.jpg');
    // Template selection must not gate photo existence.
    for (final style in ShareCardStyle.values) {
      expect(SharePayload.fromRecord(record).photoPath, payload.photoPath);
      expect(style.name, isNotEmpty);
    }
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
    expect(IntensityColors.light, isNot(IntensityColors.medium));
    expect(IntensityColors.medium, isNot(IntensityColors.dark));
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

  test('yesterday session does not belong to next local calendar day', () {
    final session = GymSession(
      gymId: gym.id,
      status: SessionStatus.secured,
      startTime: DateTime(2026, 10, 5, 18, 0),
      securedAt: DateTime(2026, 10, 5, 18, 20),
    );
    expect(session.belongsToLocalDay(DateTime(2026, 10, 5, 23, 59)), isTrue);
    expect(session.belongsToLocalDay(DateTime(2026, 10, 6, 0, 0)), isFalse);
  });

  test('todayStatus ignores previous-day session and allows fresh check-in', () {
    final oct5Session = GymSession(
      gymId: gym.id,
      status: SessionStatus.completed,
      startTime: DateTime(2026, 10, 5, 15, 0),
      endTime: DateTime(2026, 10, 5, 16, 0),
      securedAt: DateTime(2026, 10, 5, 15, 20),
    );
    final oct5Record = DailyRecord(
      dateKey: '2026-10-05',
      kind: DayKind.completed,
      gymId: gym.id,
      gymName: gym.name,
      arrivalTime: DateTime(2026, 10, 5, 15, 0),
      endTime: DateTime(2026, 10, 5, 16, 0),
      duration: const Duration(hours: 1),
      streakAtPoint: 1,
    );
    final state = AppState(
      ready: true,
      authenticated: true,
      adminAuthenticated: false,
      user: null,
      gym: gym,
      session: oct5Session,
      streak: const StreakSnapshot(current: 1, best: 1, totalGymDays: 1),
      records: {'2026-10-05': oct5Record},
      protection: const StreakProtection(),
      settings: const AppSettings(),
      location: LocationSnapshot(
        point: gym.location,
        presence: DemoPresence.inside,
      ),
      adminConfig: const AdminConfig(),
    );

    // Still 5 Oct → completed for that day.
    expect(
      state.todayStatus(DateTime(2026, 10, 5, 20, 0)),
      TodayStatus.completed,
    );
    // After midnight 6 Oct with yesterday's session still in memory → fresh.
    expect(
      state.todayStatus(DateTime(2026, 10, 6, 0, 1)),
      TodayStatus.readyToCheckIn,
    );
    // History for 5 Oct remains.
    expect(state.records['2026-10-05']?.isCompleted, isTrue);
    expect(state.records.containsKey('2026-10-06'), isFalse);
  });
}
