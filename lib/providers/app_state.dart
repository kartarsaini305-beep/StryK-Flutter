import '../core/utils/dates.dart';
import '../core/utils/geo.dart';
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
  readyToCheckIn,
  tracking,
  secured,
  leavingZone,
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
    this.onboardingSeen = false,
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
  final bool onboardingSeen;

  bool get hasName => user?.name.trim().isNotEmpty ?? false;
  bool get hasGym => gym != null;

  Duration get minStay => adminConfig.minStay;
  double get geofenceRadiusMeters => adminConfig.checkInRadiusMeters;
  double get checkInRadiusMeters => adminConfig.checkInRadiusMeters;
  double get checkOutRadiusMeters => adminConfig.checkOutRadiusMeters;
  Duration get outsideDuration => adminConfig.outsideDuration;

  Gym? get effectiveGym {
    final base = gym;
    if (base == null) return null;
    final name = adminConfig.gymNameOverride.trim().isEmpty
        ? base.name
        : adminConfig.gymNameOverride.trim();
    final lat = adminConfig.gymLatitude;
    final lng = adminConfig.gymLongitude;
    final point = (lat != null && lng != null) ? GeoPoint(lat, lng) : base.location;
    if (name == base.name && point == base.location) return base;
    return Gym(
      id: base.id,
      name: name,
      address: base.address,
      location: point,
      placeholderLabel: base.placeholderLabel,
    );
  }

  double distanceToGymMeters() {
    final g = effectiveGym;
    if (g == null) return double.infinity;
    return location.point.distanceTo(g.location);
  }

  bool get isInsideCheckIn {
    if (location.presence == DemoPresence.inside) return true;
    return distanceToGymMeters() <= checkInRadiusMeters;
  }

  /// Checkout zone is measured from stored check-in point when available.
  bool get isInsideCheckOut {
    final anchor = session?.checkInPoint ?? effectiveGym?.location;
    if (anchor == null) return isInsideCheckIn;
    if (location.presence == DemoPresence.inside) return true;
    return location.point.distanceTo(anchor) <= checkOutRadiusMeters;
  }

  /// Legacy helper used by older UI.
  bool get isInside => isInsideCheckIn;

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

  Duration? outsideCountdown([DateTime? wallNow]) {
    final leftAt = session?.leftZoneAt;
    if (leftAt == null || session?.status != SessionStatus.secured) {
      return null;
    }
    final at = sessionNow(wallNow);
    final elapsedOutside = at.difference(leftAt);
    final left = outsideDuration - elapsedOutside;
    return left.isNegative ? Duration.zero : left;
  }

  TodayStatus todayStatus([DateTime? wallNow]) {
    final wall = wallNow ?? DateTime.now();
    final current = session;

    // Previous-day sessions must not drive today's check-in UI.
    final forToday = current != null && current.belongsToLocalDay(wall);

    if (!forToday) {
      if (todayRecord(wall)?.isCompleted == true) {
        return TodayStatus.completed;
      }
      if (isInsideCheckIn) return TodayStatus.readyToCheckIn;
      return TodayStatus.notStarted;
    }

    switch (current.status) {
      case SessionStatus.completed:
        return TodayStatus.completed;
      case SessionStatus.secured:
        if (current.leftZoneAt != null && !isInsideCheckOut) {
          return TodayStatus.leavingZone;
        }
        return TodayStatus.secured;
      case SessionStatus.interrupted:
        return TodayStatus.interrupted;
      case SessionStatus.tracking:
        return TodayStatus.tracking;
      case SessionStatus.idle:
        if (todayRecord(wall)?.isCompleted == true) {
          return TodayStatus.completed;
        }
        if (isInsideCheckIn) return TodayStatus.readyToCheckIn;
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
    bool? onboardingSeen,
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
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
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
        onboardingSeen: false,
      );

  factory AppState.fromPersisted(
    PersistedApp data, {
    required AdminConfig adminConfig,
    required bool adminAuthenticated,
    bool onboardingSeen = false,
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
      onboardingSeen: onboardingSeen,
    );
  }
}
