import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../app/config.dart';
import '../core/utils/dates.dart';
import '../core/utils/session_clock.dart';
import '../features/admin/models/admin_config.dart';
import '../features/admin/services/admin_config_service.dart';
import '../features/auth/models/user_profile.dart';
import '../features/auth/services/auth_service.dart';
import '../features/gyms/models/gym.dart';
import '../features/gyms/services/gym_service.dart';
import '../features/session/models/gym_session.dart';
import '../features/session/models/location_snapshot.dart';
import '../features/session/services/location_service.dart';
import '../features/share/models/share_payload.dart';
import '../features/share/services/monthly_leaderboard_service.dart';
import '../features/share/services/verification_service.dart';
import '../features/streak/models/daily_record.dart';
import '../features/streak/services/streak_service.dart';
import '../services/firebase_phone_auth_service.dart';
import '../services/local_admin_config_service.dart';
import '../services/local_storage_service.dart';
import '../services/mock_admin_auth_service.dart';
import '../services/mock_gym_service.dart';
import '../services/mock_location_service.dart';
import '../services/mock_streak_service.dart';
import '../services/mock_verification_service.dart';
import 'app_state.dart';

final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final authServiceProvider =
    Provider<AuthService>((ref) => FirebasePhoneAuthService());
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

      // Prefer live Firebase Auth session over stale local flags.
      UserProfile? sessionUser;
      var authenticated = data.authenticated;
      try {
        sessionUser = await _auth.currentSession();
        if (sessionUser != null) {
          authenticated = true;
          final local = data.user;
          if (local != null &&
              (local.id == sessionUser.id ||
                  local.phone == sessionUser.phone ||
                  local.phone.replaceAll(RegExp(r'\D'), '').endsWith(
                        sessionUser.phone.replaceAll(RegExp(r'\D'), ''),
                      ))) {
            sessionUser = local.copyWith(
              id: sessionUser.id,
              phone: sessionUser.phone.isNotEmpty
                  ? sessionUser.phone
                  : local.phone,
            );
          }
          await _storage.setAuthenticated(true);
          await _storage.saveUser(sessionUser);
        } else {
          // Firebase signed out → do not keep a fake local login.
          authenticated = false;
          await _storage.setAuthenticated(false);
        }
      } catch (_) {
        // Firebase unavailable (e.g. widget tests) — keep local persistence.
      }

      state = AppState.fromPersisted(
        data.copyWith(
          authenticated: authenticated,
          user: sessionUser ?? data.user,
        ),
        adminConfig: config,
        adminAuthenticated: adminAuthed,
        onboardingSeen: _storage.onboardingSeen,
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

  Future<void> markOnboardingSeen() async {
    await _storage.setOnboardingSeen(true);
    state = state.copyWith(onboardingSeen: true);
  }

  Future<void> sendOtp(
    String nationalNumber, {
    bool forceResend = false,
  }) {
    final digits = nationalNumber.replaceAll(RegExp(r'\D'), '');
    final ten = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    return _auth.sendOtp(
      '${AppConfig.countryCode}$ten',
      forceResend: forceResend,
    );
  }

  Future<void> verifyOtp({
    required String nationalNumber,
    required String code,
  }) async {
    final digits = nationalNumber.replaceAll(RegExp(r'\D'), '');
    final ten = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    final phone = '${AppConfig.countryCode}$ten';
    final existing = state.user;
    final user = await _auth.verifyOtp(
      phone: phone,
      code: code,
      existing: existing,
    );
    state = state.copyWith(authenticated: true, user: user);
    await _storage.setAuthenticated(true, token: user.id);
    await _storage.saveUser(user);
  }

  /// Completes auth when Android instant verification already signed in.
  Future<bool> completeIfFirebaseSignedIn(String nationalNumber) async {
    final session = await _auth.currentSession();
    if (session == null) return false;
    final digits = nationalNumber.replaceAll(RegExp(r'\D'), '');
    final ten = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    final phone = '${AppConfig.countryCode}$ten';
    final sessionDigits = session.phone.replaceAll(RegExp(r'\D'), '');
    if (sessionDigits.isNotEmpty &&
        !sessionDigits.endsWith(ten) &&
        !ten.endsWith(sessionDigits.length > 10
            ? sessionDigits.substring(sessionDigits.length - 10)
            : sessionDigits)) {
      return false;
    }
    final user = await _auth.verifyOtp(
      phone: phone,
      code: '',
      existing: state.user,
    );
    state = state.copyWith(authenticated: true, user: user);
    await _storage.setAuthenticated(true, token: user.id);
    await _storage.saveUser(user);
    return true;
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
    String? phone,
    bool clearPhoto = false,
  }) async {
    final user = state.user;
    if (user == null) return;
    // Persist DP into documents — cropper returns a temp path that can vanish.
    String? durablePhoto = photoPath;
    if (photoPath != null && !clearPhoto) {
      final source = File(photoPath);
      if (await source.exists()) {
        final dir = await getApplicationDocumentsDirectory();
        final dest = File('${dir.path}/profile-photo.jpg');
        await source.copy(dest.path);
        durablePhoto = dest.path;
      }
    }
    final updated = user.copyWith(
      name: name,
      city: city,
      goal: goal,
      photoPath: durablePhoto,
      phone: phone,
      clearPhoto: clearPhoto,
    );
    state = state.copyWith(user: updated);
    await _storage.saveUser(updated);
  }

  Future<void> changePhoneNumber({
    required String newNationalNumber,
    required String newOtpCode,
  }) async {
    final user = state.user;
    if (user == null) return;
    final phone = '${AppConfig.countryCode}$newNationalNumber';
    final verified = await _auth.verifyOtp(
      phone: phone,
      code: newOtpCode,
      existing: user,
    );
    final updated = verified.copyWith(
      phone: phone,
      name: user.name,
      city: user.city,
      goal: user.goal,
      photoPath: user.photoPath,
    );
    state = state.copyWith(user: updated);
    await _storage.saveUser(updated);
  }

  /// Explicit check-in when inside admin check-in radius.
  Future<bool> checkIn() async {
    final gym = state.effectiveGym;
    if (gym == null || !state.adminConfig.gymDetectionEnabled) return false;
    if (!state.isInsideCheckIn) return false;
    final wall = DateTime.now();
    await _rollStaleSessionToNewLocalDay(wall);
    final session = state.session;
    if (session != null &&
        session.belongsToLocalDay(wall) &&
        (session.status == SessionStatus.tracking ||
            session.status == SessionStatus.secured ||
            session.status == SessionStatus.completed)) {
      return false;
    }
    if (state.todayRecord(wall)?.isCompleted == true) return false;
    final next = GymSession(
      gymId: gym.id,
      status: SessionStatus.tracking,
      startTime: wall,
      checkInPoint: state.location.point,
    );
    state = state.copyWith(session: next);
    await _storage.saveSession(next);
    HapticFeedback.mediumImpact();
    return true;
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

  /// Persists ONE session photo for [dateKey]. All card templates read this.
  Future<void> saveRecordPhoto(String dateKey, String? path) async {
    String? stored = path;
    if (path != null) {
      final source = File(path);
      if (await source.exists()) {
        final dir = await getApplicationDocumentsDirectory();
        final dest = File('${dir.path}/session-photo-$dateKey.jpg');
        await source.copy(dest.path);
        stored = dest.path;
      }
    }
    await _patchRecord(
      dateKey,
      (record) => record.copyWith(
        optionalPhotoPath: stored,
        clearPhoto: stored == null,
      ),
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
    try {
      await _auth.signOut();
    } catch (_) {}
    state = state.copyWith(authenticated: false);
    await _storage.setAuthenticated(false);
  }

  Future<void> deleteAccount() async {
    _syncTimer?.cancel();
    try {
      await _auth.signOut();
    } catch (_) {}
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
    final gym = state.effectiveGym;
    if (gym == null) return;
    await _applyLocation(_location.enterZone(gym));
  }

  Future<void> simulateLeaveZone() async {
    await _applyLocation(_location.leaveZone());
  }

  Future<void> simulateCompleteTwentyMinutes() async {
    final gym = state.effectiveGym;
    if (gym == null || state.session?.status == SessionStatus.completed) return;
    final wall = DateTime.now();
    // Jump start so elapsed ≈ minStay under current clock (demo or real).
    final start = state.adminConfig.demoTimeMode
        ? wall.subtract(Duration(seconds: state.minStay.inMinutes))
        : wall.subtract(state.minStay);
    final location = _location.enterZone(gym);
    final session = GymSession(
      gymId: gym.id,
      status: SessionStatus.tracking,
      startTime: start,
      checkInPoint: location.point,
    );
    state = state.copyWith(session: session, location: location);
    await _storage.saveSession(session);
    await _storage.saveLocation(location);
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

    // Midnight / next-day open: never reuse yesterday's active session as today.
    await _rollStaleSessionToNewLocalDay(wallNow);

    final gym = state.effectiveGym!;
    var session = state.session ?? GymSession.idle(gym.id);
    final sessionTime = state.sessionNow(wallNow);

    if (session.status == SessionStatus.completed) return;

    // Pre-secure: leaving check-in zone interrupts (streak not secured yet).
    if (!state.isInsideCheckIn && session.status == SessionStatus.tracking) {
      session = session.copyWith(
        status: SessionStatus.interrupted,
        endTime: sessionTime,
        clearLeftZone: true,
      );
      state = state.copyWith(session: session);
      await _storage.saveSession(session);
      HapticFeedback.heavyImpact();
      return;
    }

    // Secured: checkout uses check-in location + continuous outside duration.
    if (session.status == SessionStatus.secured) {
      if (state.isInsideCheckOut) {
        if (session.leftZoneAt != null) {
          final cleared = session.copyWith(
            clearLeftZone: true,
            endTime: sessionTime,
          );
          state = state.copyWith(session: cleared);
          await _storage.saveSession(cleared);
        } else {
          final live = session.copyWith(endTime: sessionTime);
          state = state.copyWith(session: live);
        }
        return;
      }

      // Outside checkout radius — start / continue outside timer.
      final leftAt = session.leftZoneAt ?? sessionTime;
      final withLeft = session.leftZoneAt == null
          ? session.copyWith(leftZoneAt: leftAt, endTime: sessionTime)
          : session.copyWith(endTime: sessionTime);
      if (session.leftZoneAt == null) {
        state = state.copyWith(session: withLeft);
        await _storage.saveSession(withLeft);
      } else {
        state = state.copyWith(session: withLeft);
      }

      final outsideFor = sessionTime.difference(withLeft.leftZoneAt!);
      if (outsideFor >= state.outsideDuration) {
        await _finalizeCheckout(sessionTime, withLeft);
      }
      return;
    }

    if (session.isActive &&
        session.startTime != null &&
        state.isInsideCheckIn) {
      final elapsed = state.elapsed(wallNow);
      if (session.status == SessionStatus.tracking && elapsed >= state.minStay) {
        await _secureDay(sessionTime, session);
        return;
      }
      final live = session.copyWith(
        endTime: sessionTime,
        checkInPoint: session.checkInPoint ?? state.location.point,
        clearLeftZone: true,
      );
      state = state.copyWith(session: live);
    }
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
      await _syncMonthlyLeaderboard();
    } else {
      state = state.copyWith(session: secured);
    }
    await _storage.saveSession(secured);
    HapticFeedback.heavyImpact();
  }

  Future<void> _syncMonthlyLeaderboard() async {
    final user = state.user;
    if (user == null) return;
    final month = MonthlyLeaderboardService.monthKey();
    final days = MonthlyLeaderboardService.verifiedDaysForMonth(
      state.records,
      month,
    );
    await MonthlyLeaderboardService().syncUserEntry(
      userId: user.id,
      displayName: user.name.trim().isEmpty ? 'Athlete' : user.name.trim(),
      verifiedDays: days,
      gymName: state.effectiveGym?.name ?? '',
    );
  }

  Future<void> _finalizeCheckout(
    DateTime sessionTime,
    GymSession session, {
    DateTime? recordDay,
  }) async {
    final start = session.startTime;
    if (start == null) return;
    final duration = sessionTime.difference(start);
    final finished = session.copyWith(
      status: SessionStatus.completed,
      endTime: sessionTime,
      securedAt: session.securedAt ?? sessionTime,
    );
    // Always attribute checkout to the session's local calendar day.
    final key = Dates.key(recordDay ?? start);
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
    await _syncMonthlyLeaderboard();
    HapticFeedback.mediumImpact();
  }

  /// Closes a previous-day session per existing rules, then starts a fresh
  /// idle shell for the current local calendar day. History / streak untouched
  /// except updating endTime on an already-secured prior-day record.
  Future<void> _rollStaleSessionToNewLocalDay(DateTime wallNow) async {
    final gym = state.gym;
    final session = state.session;
    if (gym == null || session == null) return;
    if (session.belongsToLocalDay(wallNow)) return;

    final start = session.startTime;
    if (start != null) {
      final closeAt = session.endTime ??
          DateTime(start.year, start.month, start.day, 23, 59, 59);

      switch (session.status) {
        case SessionStatus.secured:
          await _finalizeCheckout(closeAt, session, recordDay: start);
          break;
        case SessionStatus.tracking:
          final liveElapsed = SessionClock.elapsed(
            wallNow: closeAt,
            config: state.adminConfig,
            sessionStart: start,
          );
          if (liveElapsed >= state.minStay) {
            // Min stay was met but never checked out — close on prior day.
            final secured = session.copyWith(
              status: SessionStatus.secured,
              securedAt: session.securedAt ?? closeAt,
              endTime: closeAt,
            );
            final already =
                state.records[Dates.key(start)]?.isCompleted == true;
            if (!already && state.adminConfig.streakEnabled) {
              final update = _streak.completeSession(
                now: start,
                gym: gym,
                session: secured,
                streak: state.streak,
                records: Map<String, DailyRecord>.from(state.records),
                protection: state.protection,
              );
              final key = Dates.key(start);
              final stamped = Map<String, DailyRecord>.from(update.records);
              final completed = stamped[key];
              if (completed != null && completed.isCompleted) {
                stamped[key] = _verification.stamp(completed);
              }
              state = state.copyWith(
                streak: update.streak,
                records: stamped,
                protection: update.protection,
              );
              await _storage.saveStreak(update.streak);
              await _storage.saveRecords(stamped);
              await _storage.saveProtection(update.protection);
            }
            await _finalizeCheckout(closeAt, secured, recordDay: start);
          } else {
            final interrupted = session.copyWith(
              status: SessionStatus.interrupted,
              endTime: closeAt,
              clearLeftZone: true,
            );
            state = state.copyWith(session: interrupted);
            await _storage.saveSession(interrupted);
          }
          break;
        case SessionStatus.completed:
        case SessionStatus.interrupted:
        case SessionStatus.idle:
          break;
      }
    }

    final idle = GymSession.idle(gym.id);
    state = state.copyWith(session: idle);
    await _storage.saveSession(idle);
  }
}

String? destinationFor(AppState state) {
  if (!state.ready) return null;
  if (!state.authenticated) {
    return state.onboardingSeen ? '/phone' : '/onboarding';
  }
  if (!state.hasName) return '/name';
  if (!state.hasGym) return '/select-gym';
  return '/home';
}
