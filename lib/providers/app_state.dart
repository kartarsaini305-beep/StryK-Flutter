import '../core/utils/dates.dart';
import '../core/utils/session_clock.dart';
import '../features/admin/models/admin_config.dart';
import '../features/auth/models/user_profile.dart';
import '../features/gyms/models/gym.dart';
import '../features/profile/models/app_settings.dart';
import '../features/session/models/gym_session.dart';
import '../features/session/models/location_snapshot.dart';
import '../features/streak/models/daily_record.dart';
import '../features/streak/models/streak_protection.dart';
import '../features/streak/models/streak_snapshot.dart';
import '../services/local_storage_service.dart';
import '../services/mock_location_service.dart';

enum TodayStatus {
  notStarted,
  gymDetected,
  tracking,
  secured,
  interrupted,
  completed,
}

class AppState {
  const AppState({
    required this.ready,
    required this.authenticated,
    required this.adminAuthenticated,
    required this.user,
    required this.gym,
    required this.session,
    required this.streak,
    required this.records,
    required this.protection,
    required this.settings,
    required this.location,
    required this.adminConfig,
  });

  final bool ready;
  final bool authenticated;
  final bool adminAuthenticated;
  final UserProfile? user;
  final Gym? gym;
  final GymSession? session;
  final StreakSnapshot streak;
  final Map<String, DailyRecord> records;
  final StreakProtection protection;
  final AppSettings settings;
  final LocationSnapshot location;
  final AdminConfig adminConfig;

  bool get hasName => user?.name.trim().isNotEmpty ?? false;
  bool get hasGym => gym != null;
  bool get isInside => location.presence == DemoPresence.inside;

  Duration get minStay => adminConfig.minStay;
  double get geofenceRadiusMeters => adminConfig.geofenceRadiusMeters;

  DailyRecord? todayRecord([DateTime? now]) =>
      records[Dates.key(now ?? DateTime.now())];

  DateTime sessionNow([DateTime? wallNow]) {
    final wall = wallNow ?? DateTime.now();
    return SessionClock.now(
      wallNow: wall,
      config: adminConfig,
      sessionStart: session?.startTime,
    );
  }

  TodayStatus todayStatus([DateTime? wallNow]) {
    final wall = wallNow ?? DateTime.now();
    final at = sessionNow(wall);
    final current = session;

    switch (current?.status) {
      case SessionStatus.completed:
        return TodayStatus.completed;
      case SessionStatus.secured:
        return TodayStatus.secured;
      case SessionStatus.interrupted:
        return TodayStatus.interrupted;
      case SessionStatus.tracking:
        final start = current!.startTime;
        if (start != null &&
            at.difference(start) < const Duration(milliseconds: 1400)) {
          return TodayStatus.gymDetected;
        }
        return TodayStatus.tracking;
      case SessionStatus.idle:
      case null:
        if (todayRecord(wall)?.isCompleted == true) {
          return TodayStatus.completed;
        }
        return TodayStatus.notStarted;
    }
  }

  Duration remaining([DateTime? wallNow]) {
    final current = session;
    if (current == null || current.startTime == null || !current.isActive) {
      return minStay;
    }
    final left = minStay - elapsed(wallNow);
    return left.isNegative ? Duration.zero : left;
  }

  Duration elapsed([DateTime? wallNow]) {
    final wall = wallNow ?? DateTime.now();
    final current = session;
    if (current?.status == SessionStatus.completed) {
      return current!.elapsed();
    }
    return SessionClock.elapsed(
      wallNow: wall,
      config: adminConfig,
      sessionStart: current?.startTime,
    );
  }

  AppState copyWith({
    bool? ready,
    bool? authenticated,
    bool? adminAuthenticated,
    UserProfile? user,
    Gym? gym,
    GymSession? session,
    StreakSnapshot? streak,
    Map<String, DailyRecord>? records,
    StreakProtection? protection,
    AppSettings? settings,
    LocationSnapshot? location,
    AdminConfig? adminConfig,
    bool clearGym = false,
    bool clearSession = false,
    bool clearUser = false,
  }) {
    return AppState(
      ready: ready ?? this.ready,
      authenticated: authenticated ?? this.authenticated,
      adminAuthenticated: adminAuthenticated ?? this.adminAuthenticated,
      user: clearUser ? null : (user ?? this.user),
      gym: clearGym ? null : (gym ?? this.gym),
      session: clearSession ? null : (session ?? this.session),
      streak: streak ?? this.streak,
      records: records ?? this.records,
      protection: protection ?? this.protection,
      settings: settings ?? this.settings,
      location: location ?? this.location,
      adminConfig: adminConfig ?? this.adminConfig,
    );
  }

  factory AppState.initial() => AppState(
        ready: false,
        authenticated: false,
        adminAuthenticated: false,
        user: null,
        gym: null,
        session: null,
        streak: const StreakSnapshot(),
        records: const {},
        protection: const StreakProtection(),
        settings: const AppSettings(),
        location: LocationSnapshot(
          point: MockLocationService.outsidePoint,
          presence: DemoPresence.outside,
        ),
        adminConfig: const AdminConfig(),
      );

  factory AppState.fromPersisted(
    PersistedApp data, {
    required AdminConfig adminConfig,
    required bool adminAuthenticated,
  }) {
    return AppState(
      ready: true,
      authenticated: data.authenticated,
      adminAuthenticated: adminAuthenticated,
      user: data.user,
      gym: data.gym,
      session: data.session,
      streak: data.streak,
      records: data.records,
      protection: data.protection,
      settings: data.settings,
      location: data.location,
      adminConfig: adminConfig,
    );
  }
}
