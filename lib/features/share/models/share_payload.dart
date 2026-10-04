import '../../streak/models/daily_record.dart';

enum ShareCardStyle { minimal, photo, achievement }

extension ShareCardStyleX on ShareCardStyle {
  String get label => switch (this) {
        ShareCardStyle.minimal => 'Minimal',
        ShareCardStyle.photo => 'Photo',
        ShareCardStyle.achievement => 'Achievement',
      };

  String get caption => switch (this) {
        ShareCardStyle.minimal => 'Clean. Focused. Premium.',
        ShareCardStyle.photo => 'Your gym. Your moment.',
        ShareCardStyle.achievement => 'Bold. Motivating. Share-worthy.',
      };

  static ShareCardStyle parse(String? value) {
    // Migrate older style names if present in storage.
    if (value == 'raw' || value == 'cinema') return ShareCardStyle.minimal;
    return ShareCardStyle.values.firstWhere(
      (style) => style.name == value,
      orElse: () => ShareCardStyle.minimal,
    );
  }
}

class SharePayload {
  const SharePayload({
    required this.dayNumber,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.gymName,
    required this.totalGymDays,
    required this.verificationId,
    required this.verificationUrl,
    this.photoPath,
  });

  final int dayNumber;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final String gymName;
  final int totalGymDays;
  final String verificationId;
  final String verificationUrl;
  final String? photoPath;

  /// Back-compat alias used by older callers.
  DateTime get time => startTime;

  factory SharePayload.fromRecord(DailyRecord record) {
    final date = record.calendarDate;
    final start = record.arrivalTime ?? date;
    final end = record.endTime ??
        start.add(record.duration ?? const Duration(minutes: 20));
    final duration = record.duration ?? end.difference(start);
    return SharePayload(
      dayNumber: record.streakAtPoint ?? 0,
      date: date,
      startTime: start,
      endTime: end,
      duration: duration.isNegative ? Duration.zero : duration,
      gymName: record.gymName ?? 'Gym',
      totalGymDays: record.totalGymDaysAtThatTime ?? record.streakAtPoint ?? 0,
      verificationId: record.verificationId ?? 'SK-000000',
      verificationUrl: record.verificationUrl ??
          'https://stryk.app/verify/${record.verificationId ?? 'SK-000000'}',
      photoPath: record.optionalPhotoPath,
    );
  }
}
