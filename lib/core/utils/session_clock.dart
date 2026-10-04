import '../../features/admin/models/admin_config.dart';

/// Converts wall-clock time into session time.
/// When [AdminConfig.demoTimeMode] is on: 1 real second = 1 simulated minute.
abstract final class SessionClock {
  static DateTime now({
    required DateTime wallNow,
    required AdminConfig config,
    DateTime? sessionStart,
  }) {
    if (!config.demoTimeMode || sessionStart == null) return wallNow;
    final real = wallNow.difference(sessionStart);
    if (real.isNegative) return wallNow;
    return sessionStart.add(
      Duration(milliseconds: real.inMilliseconds * 60),
    );
  }

  static Duration elapsed({
    required DateTime wallNow,
    required AdminConfig config,
    required DateTime? sessionStart,
    DateTime? sessionEnd,
  }) {
    if (sessionStart == null) return Duration.zero;
    final end = sessionEnd ??
        now(wallNow: wallNow, config: config, sessionStart: sessionStart);
    final value = end.difference(sessionStart);
    return value.isNegative ? Duration.zero : value;
  }
}
