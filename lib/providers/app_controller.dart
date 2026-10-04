import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/config.dart';
import '../core/utils/dates.dart';
import '../features/admin/models/admin_config.dart';
import '../features/admin/services/admin_config_service.dart';
import '../features/auth/services/auth_service.dart';
import '../features/gyms/models/gym.dart';
import '../features/gyms/services/gym_service.dart';
import '../features/session/models/gym_session.dart';
import '../features/session/models/location_snapshot.dart';
import '../features/session/services/location_service.dart';
import '../features/share/models/share_payload.dart';
import '../features/share/services/verification_service.dart';
import '../features/streak/models/daily_record.dart';
import '../features/streak/services/streak_service.dart';
import '../services/local_admin_config_service.dart';
import '../services/local_storage_service.dart';
import '../services/mock_admin_auth_service.dart';
import '../services/mock_auth_service.dart';
import '../services/mock_gym_service.dart';
import '../services/mock_location_service.dart';
import '../services/mock_streak_service.dart';
import '../services/mock_verification_service.dart';
import 'app_state.dart';

final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final authServiceProvider = Provider<AuthService>((ref) => MockAuthService());
final gymServiceProvider = Provider<GymService>((ref) => MockGymService());
final streakServiceProvider = Provider<StreakService>((ref) => MockStreakService());

final locationServiceProvider =
    Provider<LocationService>((ref) => MockLocationService());

final verificationServiceProvider =
    Provider<VerificationService>((ref) => MockVerificationService());

final adminConfigServiceProvider = Provider<AdminConfigService>((ref) {
  return LocalAdminConfigService();
});

final adminAuthServiceProvider = Provider<MockAdminAuthService>((ref) {
  return MockAdminAuthService();
});

final tickerProvider = StreamProvider<DateTime>((ref) {
  return Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  ).asBroadcastStream();
});

final appControllerProvider =
    NotifierProvider<AppController, AppState>(AppController.new);

class AppController extends Notifier<AppState> {
  Timer? _syncTimer;

  LocalStorageService get _storage => ref.read(localStorageProvider);
  AuthService get _auth => ref.read(authServiceProvider);
  LocationService get _location => ref.read(locationServiceProvider);
  StreakService get _streak => ref.read(streakServiceProvider);
  VerificationService get _verification => ref.read(verificationServiceProvider);
  AdminConfigService get _adminConfig => ref.read(adminConfigServiceProvider);
  MockAdminAuthService get _adminAuth => ref.read(adminAuthServiceProvider);

  var _bootstrapped = false;

  @override
  AppState build() {
    ref.onDispose(() => _syncTimer?.cancel());
    if (!_bootstrapped) {
      _bootstrapped = true;
      Future.microtask(hydrate);
    }
    return AppState.initial();
  }

  Future<void> hydrate() async {
    try {
      await _storage.init();
      final data = await _storage.load();
      final config = await _adminConfig.load();
      final adminAuthed = await _adminAuth.hasAdminSession();
      state = AppState.fromPersisted(
        data,
        adminConfig: config,
        adminAuthenticated: adminAuthed,
      );
    } catch (_) {
      state = AppState.initial().copyWith(ready: true);
    }
    _startSyncLoop();
    await syncSession(DateTime.now());
  }

  void _startSyncLoop() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      syncSession(DateTime.now());
    });
  }

  Future<void> sendOtp(String nationalNumber) {
    return _auth.sendOtp('${AppConfig.countryCode}$nationalNumber');
  }

  Future<void> verifyOtp({
    required String nationalNumber,
    required String code,
  }) async {
    final phone = '${AppConfig.countryCode}$nationalNumber';
    final user = await _auth.verifyOtp(
      phone: phone,
      code: code,
      existing: state.user?.phone == phone ? state.user : null,
    );
    state = state.copyWith(authenticated: true, user: user);
    await _storage.setAuthenticated(true);
    await _storage.saveUser(user);
  }

  Future<void> sendAdminOtp(String nationalNumber) {
    return _adminAuth.sendAdminOtp(nationalNumber);
  }

  Future<void> verifyAdminOtp({
    required String nationalNumber,
    required String code,
  }) async {
    await _adminAuth.verifyAdminOtp(phone: nationalNumber, code: code);
    state = state.copyWith(adminAuthenticated: true);
  }

  Future<void> logoutAdmin() async {
    await _adminAuth.clearAdminSession();
    state = state.copyWith(adminAuthenticated: false);
  }

  Future<void> updateAdminConfig(AdminConfig config) async {
    await _adminConfig.save(config);
    state = state.copyWith(adminConfig: config);
  }

  Future<void> saveName(String name) async {
    final user = state.user;
    if (user == null) return;
    final updated = user.copyWith(name: name.trim());
    state = state.copyWith(user: updated);
    await _storage.saveUser(updated);
  }

  Future<void> saveProfile({
    String? name,
    String? city,
    String? goal,
    String? photoPath,
    bool clearPhoto = false,
  }) async {
    final user = state.user;
    if (user == null) return;
    final updated = user.copyWith(
      name: name,
      city: city,
      goal: goal,
      photoPath: photoPath,
      clearPhoto: clearPhoto,
    );
    state = state.copyWith(user: updated);
    await _storage.saveUser(updated);
  }

  Future<void> selectGym(Gym gym) async {
    final session = GymSession.idle(gym.id);
    state = state.copyWith(gym: gym, session: session);
    await _storage.saveGym(gym);
    await _storage.saveSession(session);
  }

  Future<void> setNotifications(bool enabled) async {
    final settings = state.settings.copyWith(
      notificationsEnabled: enabled,
      arrivalNudges: enabled,
    );
    state = state.copyWith(settings: settings);
    await _storage.saveSettings(settings);
  }

  Future<void> setArrivalNudges(bool enabled) async {
    final settings = state.settings.copyWith(arrivalNudges: enabled);
    state = state.copyWith(settings: settings);
    await _storage.saveSettings(settings);
  }

  Future<void> setRestDayProtection(bool enabled) async {
    final settings = state.settings.copyWith(restDayProtection: enabled);
    state = state.copyWith(settings: settings);
    await _storage.saveSettings(settings);
  }

  DailyRecord? recordFor(String dateKey) => state.records[dateKey];

  Future<void> saveCardStyle(String dateKey, ShareCardStyle style) async {
    await _patchRecord(dateKey, (record) => record.copyWith(cardStyle: style.name));
  }

  Future<void> saveRecordPhoto(String dateKey, String? path) async {
    await _patchRecord(
      dateKey,
      (record) =>
          record.copyWith(optionalPhotoPath: path, clearPhoto: path == null),
    );
  }

  Future<void> _patchRecord(
    String dateKey,
    DailyRecord Function(DailyRecord record) update,
  ) async {
    final current = state.records[dateKey];
    if (current == null) return;
    final records = Map<String, DailyRecord>.from(state.records)
      ..[dateKey] = update(current);
    state = state.copyWith(records: records);
    await _storage.saveRecords(records);
  }

  Future<void> seedDemoHistory() async {
    final gym = state.gym;
    if (gym == null) return;
    final records = Map<String, DailyRecord>.from(state.records);
    final now = DateTime.now();
    var current = 22;
    var total = 22;
    for (var i = 6; i >= 1; i--) {
      final day = now.subtract(Duration(days: i));
      final key = Dates.key(day);
      if (records[key]?.isCompleted == true) {
        current++;
        total++;
        continue;
      }
      if (Dates.isSunday(day)) {
        records[key] = DailyRecord(
          dateKey: key,
          kind: DayKind.sundayProtected,
          wasSundayProtected: true,
        );
        continue;
      }
      current++;
      total++;
      final arrival = DateTime(day.year, day.month, day.day, 15, 4);
      final stay = Duration(minutes: state.minStay.inMinutes + i * 3);
      final record = DailyRecord(
        dateKey: key,
        kind: DayKind.completed,
        gymId: gym.id,
        gymName: gym.name,
        arrivalTime: arrival,
        endTime: arrival.add(stay),
        duration: stay,
        streakAtPoint: current,
        totalGymDaysAtThatTime: total,
      );
      records[key] = _verification.stamp(record);
    }
    final streak = state.streak.copyWith(
      current: current > state.streak.current ? current : state.streak.current,
      best: current > state.streak.best ? current : state.streak.best,
      totalGymDays:
          total > state.streak.totalGymDays ? total : state.streak.totalGymDays,
    );
    state = state.copyWith(records: records, streak: streak);
    await _storage.saveRecords(records);
    await _storage.saveStreak(streak);
  }

  Future<void> logout() async {
    state = state.copyWith(authenticated: false);
    await _storage.setAuthenticated(false);
  }

  Future<void> deleteAccount() async {
    _syncTimer?.cancel();
    await _storage.clearAll();
    state = AppState.initial().copyWith(
      ready: true,
      adminConfig: state.adminConfig,
      adminAuthenticated: state.adminAuthenticated,
    );
    _startSyncLoop();
  }

  Future<void> simulateOutside() async {
    await _applyLocation(_location.outsideGym());
  }

  Future<void> simulateEnterZone() async {
    final gym = state.gym;
    if (gym == null) return;
    await _applyLocation(_location.enterZone(gym));
  }

  Future<void> simulateLeaveZone() async {
    await _applyLocation(_location.leaveZone());
  }

  Future<void> simulateCompleteTwentyMinutes() async {
    final gym = state.gym;
    if (gym == null || state.session?.status == SessionStatus.completed) return;
    final wall = DateTime.now();
    // Jump start so elapsed ≈ minStay under current clock (demo or real).
    final start = state.adminConfig.demoTimeMode
        ? wall.subtract(Duration(seconds: state.minStay.inMinutes))
        : wall.subtract(state.minStay);
    final session = GymSession(
      gymId: gym.id,
      status: SessionStatus.tracking,
      startTime: start,
    );
    state = state.copyWith(
      session: session,
      location: _location.enterZone(gym),
    );
    await _storage.saveSession(session);
    await _storage.saveLocation(state.location);
    await syncSession(wall);
  }

  Future<void> resetToday() async {
    final gym = state.gym;
    final key = Dates.key(DateTime.now());
    final today = state.records[key];
    final records = Map<String, DailyRecord>.from(state.records)..remove(key);
    var streak = state.streak;
    if (today?.isCompleted == true) {
      streak = streak.copyWith(
        current: (streak.current - 1).clamp(0, streak.current),
        totalGymDays: (streak.totalGymDays - 1).clamp(0, streak.totalGymDays),
      );
    }
    final session = gym == null ? null : GymSession.idle(gym.id);
    final location = _location.outsideGym();
    state = state.copyWith(
      records: records,
      streak: streak,
      session: session,
      location: location,
      clearSession: gym == null,
    );
    await _storage.saveRecords(records);
    await _storage.saveStreak(streak);
    await _storage.saveSession(session);
    await _storage.saveLocation(location);
  }

  Future<void> retryAfterInterrupt() async {
    final gym = state.gym;
    if (gym == null) return;
    final session = GymSession.idle(gym.id);
    state = state.copyWith(session: session);
    await _storage.saveSession(session);
  }

  /// Finalize session with actual checkout time. Enables "Get Your Card".
  Future<void> checkoutSession() async {
    final session = state.session;
    if (session == null || session.startTime == null) return;
    if (session.status != SessionStatus.secured &&
        !(session.status == SessionStatus.tracking &&
            state.elapsed() >= state.minStay)) {
      return;
    }
    final wall = DateTime.now();
    final sessionTime = state.sessionNow(wall);
    await _finalizeCheckout(sessionTime, session);
  }

  Future<void> syncSession(DateTime wallNow) async {
    if (!state.ready || state.gym == null) return;
    if (!state.adminConfig.gymDetectionEnabled) return;

    final gym = state.gym!;
    final inside = _isInsideGym(gym);
    var session = state.session ?? GymSession.idle(gym.id);
    final sessionTime = state.sessionNow(wallNow);

    if (session.status == SessionStatus.completed) return;

    if (inside &&
        (session.status == SessionStatus.idle ||
            session.status == SessionStatus.interrupted)) {
      session = GymSession(
        gymId: gym.id,
        status: SessionStatus.tracking,
        startTime: wallNow,
      );
      state = state.copyWith(session: session);
      await _storage.saveSession(session);
      HapticFeedback.mediumImpact();
      return;
    }

    if (!inside && session.status == SessionStatus.tracking) {
      session = session.copyWith(
        status: SessionStatus.interrupted,
        endTime: sessionTime,
      );
      state = state.copyWith(session: session);
      await _storage.saveSession(session);
      HapticFeedback.heavyImpact();
      return;
    }

    if (!inside && session.status == SessionStatus.secured) {
      await _finalizeCheckout(sessionTime, session);
      return;
    }

    if (session.isActive && session.startTime != null && inside) {
      final elapsed = state.elapsed(wallNow);
      if (session.status == SessionStatus.tracking && elapsed >= state.minStay) {
        await _secureDay(sessionTime, session);
        return;
      }
      // Keep live end marker while active (timer continues after min).
      final live = session.copyWith(endTime: sessionTime);
      state = state.copyWith(session: live);
    }
  }

  bool _isInsideGym(Gym gym) {
    final distance = state.location.point.distanceTo(gym.location);
    return state.location.presence == DemoPresence.inside ||
        distance <= state.geofenceRadiusMeters;
  }

  Future<void> _applyLocation(LocationSnapshot snapshot) async {
    state = state.copyWith(location: snapshot);
    await _storage.saveLocation(snapshot);
    await syncSession(DateTime.now());
  }

  /// Award streak when min stay is reached — timer keeps running.
  Future<void> _secureDay(DateTime sessionTime, GymSession session) async {
    final gym = state.gym!;
    final secured = session.copyWith(
      status: SessionStatus.secured,
      securedAt: sessionTime,
      endTime: sessionTime,
    );

    final already = state.todayRecord()?.isCompleted == true;
    if (!already && state.adminConfig.streakEnabled) {
      final update = _streak.completeSession(
        now: sessionTime,
        gym: gym,
        session: secured,
        streak: state.streak,
        records: Map<String, DailyRecord>.from(state.records),
        protection: state.protection,
      );
      final key = Dates.key(sessionTime);
      final stamped = Map<String, DailyRecord>.from(update.records);
      final completed = stamped[key];
      if (completed != null && completed.isCompleted) {
        stamped[key] = _verification.stamp(completed);
      }
      state = state.copyWith(
        session: secured,
        streak: update.streak,
        records: stamped,
        protection: update.protection,
      );
      await _storage.saveStreak(update.streak);
      await _storage.saveRecords(stamped);
      await _storage.saveProtection(update.protection);
    } else {
      state = state.copyWith(session: secured);
    }
    await _storage.saveSession(secured);
    HapticFeedback.heavyImpact();
  }

  Future<void> _finalizeCheckout(
    DateTime sessionTime,
    GymSession session,
  ) async {
    final start = session.startTime;
    if (start == null) return;
    final duration = sessionTime.difference(start);
    final finished = session.copyWith(
      status: SessionStatus.completed,
      endTime: sessionTime,
      securedAt: session.securedAt ?? sessionTime,
    );
    final key = Dates.key(sessionTime);
    final records = Map<String, DailyRecord>.from(state.records);
    final existing = records[key];
    if (existing != null && existing.isCompleted) {
      records[key] = existing.copyWith(
        endTime: sessionTime,
        duration: duration.isNegative ? Duration.zero : duration,
      );
    }
    state = state.copyWith(session: finished, records: records);
    await _storage.saveSession(finished);
    await _storage.saveRecords(records);
    HapticFeedback.mediumImpact();
  }
}

String? destinationFor(AppState state) {
  if (!state.ready) return null;
  if (!state.authenticated) return '/welcome';
  if (!state.hasName) return '/name';
  if (!state.hasGym) return '/select-gym';
  return '/home';
}
