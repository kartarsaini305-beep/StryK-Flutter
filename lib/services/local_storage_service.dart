import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/models/user_profile.dart';
import '../features/gyms/models/gym.dart';
import '../features/profile/models/app_settings.dart';
import '../features/session/models/gym_session.dart';
import '../features/session/models/location_snapshot.dart';
import '../features/streak/models/daily_record.dart';
import '../features/streak/models/streak_protection.dart';
import '../features/streak/models/streak_snapshot.dart';
import 'mock_location_service.dart';

class PersistedApp {
  const PersistedApp({
    required this.authenticated,
    required this.user,
    required this.gym,
    required this.session,
    required this.streak,
    required this.records,
    required this.protection,
    required this.settings,
    required this.location,
  });

  final bool authenticated;
  final UserProfile? user;
  final Gym? gym;
  final GymSession? session;
  final StreakSnapshot streak;
  final Map<String, DailyRecord> records;
  final StreakProtection protection;
  final AppSettings settings;
  final LocationSnapshot location;

  PersistedApp copyWith({
    bool? authenticated,
    UserProfile? user,
    bool clearUser = false,
  }) {
    return PersistedApp(
      authenticated: authenticated ?? this.authenticated,
      user: clearUser ? null : (user ?? this.user),
      gym: gym,
      session: session,
      streak: streak,
      records: records,
      protection: protection,
      settings: settings,
      location: location,
    );
  }
}

class LocalStorageService {
  LocalStorageService({
    this._prefs,
    FlutterSecureStorage? secure,
  }) : _secure = secure ?? const FlutterSecureStorage();

  SharedPreferences? _prefs;
  final FlutterSecureStorage _secure;

  static const _authKey = 'auth_token';
  static const _userKey = 'user';
  static const _gymKey = 'gym';
  static const _sessionKey = 'session';
  static const _streakKey = 'streak';
  static const _recordsKey = 'records';
  static const _protectionKey = 'protection';
  static const _settingsKey = 'settings';
  static const _locationKey = 'location';
  static const _onboardingKey = 'onboarding_seen';

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  bool get onboardingSeen => prefs.getBool(_onboardingKey) ?? false;

  Future<void> setOnboardingSeen(bool value) async {
    await prefs.setBool(_onboardingKey, value);
  }

  SharedPreferences get prefs {
    final value = _prefs;
    if (value == null) {
      throw StateError('LocalStorageService.init() must run first.');
    }
    return value;
  }

  Future<PersistedApp> load() async {
    final token = await _secure.read(key: _authKey);
    return PersistedApp(
      authenticated: token != null && token.isNotEmpty,
      user: _readObject(_userKey, UserProfile.fromJson),
      gym: _readObject(_gymKey, Gym.fromJson),
      session: _readObject(_sessionKey, GymSession.fromJson),
      streak: _readObject(_streakKey, StreakSnapshot.fromJson) ??
          const StreakSnapshot(),
      records: _readRecords(),
      protection: _readObject(_protectionKey, StreakProtection.fromJson) ??
          const StreakProtection(),
      settings: _readObject(_settingsKey, AppSettings.fromJson) ??
          const AppSettings(),
      location: _readObject(_locationKey, LocationSnapshot.fromJson) ??
          LocationSnapshot(
            point: MockLocationService.outsidePoint,
            presence: DemoPresence.outside,
          ),
    );
  }

  Future<void> setAuthenticated(bool value, {String? token}) async {
    if (value) {
      await _secure.write(key: _authKey, value: token ?? 'demo-session');
    } else {
      await _secure.delete(key: _authKey);
    }
  }

  Future<void> saveUser(UserProfile? user) async {
    if (user == null) {
      await prefs.remove(_userKey);
    } else {
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
    }
  }

  Future<void> saveGym(Gym? gym) async {
    if (gym == null) {
      await prefs.remove(_gymKey);
    } else {
      await prefs.setString(_gymKey, jsonEncode(gym.toJson()));
    }
  }

  Future<void> saveSession(GymSession? session) async {
    if (session == null) {
      await prefs.remove(_sessionKey);
    } else {
      await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
    }
  }

  Future<void> saveStreak(StreakSnapshot streak) async {
    await prefs.setString(_streakKey, jsonEncode(streak.toJson()));
  }

  Future<void> saveRecords(Map<String, DailyRecord> records) async {
    final encoded = records.map((key, value) => MapEntry(key, value.toJson()));
    await prefs.setString(_recordsKey, jsonEncode(encoded));
  }

  Future<void> saveProtection(StreakProtection protection) async {
    await prefs.setString(_protectionKey, jsonEncode(protection.toJson()));
  }

  Future<void> saveSettings(AppSettings settings) async {
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<void> saveLocation(LocationSnapshot location) async {
    await prefs.setString(_locationKey, jsonEncode(location.toJson()));
  }

  Future<void> clearAll() async {
    await _secure.deleteAll();
    await prefs.clear();
  }

  T? _readObject<T>(String key, T Function(Map<String, dynamic>) parse) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    return parse(jsonDecode(raw) as Map<String, dynamic>);
  }

  Map<String, DailyRecord> _readRecords() {
    final raw = prefs.getString(_recordsKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        key,
        DailyRecord.fromJson(value as Map<String, dynamic>),
      ),
    );
  }
}
