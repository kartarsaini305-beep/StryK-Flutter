import '../../streak/models/daily_record.dart';

enum ShareCardStyle { minimal, photo, achievement }

extension ShareCardStyleX on ShareCardStyle {
  String get label => switch (this) {
        ShareCardStyle.minimal => 'Minimal',
        ShareCardStyle.photo => 'Photo',
        ShareCardStyle.achievement => 'Progress',
      };

  String get caption => switch (this) {
        ShareCardStyle.minimal => 'Clean. Focused. Premium.',
        ShareCardStyle.photo => 'Your gym. Your moment.',
        ShareCardStyle.achievement => 'Rank · streak · share-ready.',
      };

  static ShareCardStyle parse(String? value) {
    if (value == 'raw' || value == 'cinema') return ShareCardStyle.minimal;
    return ShareCardStyle.values.firstWhere(
      (style) => style.name == value,
      orElse: () => ShareCardStyle.minimal,
    );
  }
}

class ShareSponsor {
  const ShareSponsor({required this.name, this.logoUrl = ''});
  final String name;
  final String logoUrl;
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
    this.gymRank,
    this.strykScore,
    this.sponsors = const [],
    this.displayName = '',
    this.profilePhotoPath,
    this.currentStreak,
    this.bestStreak,
    this.verifiedDaysMonth,
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
  /// 1-based rank inside the user's gym this month.
  final int? gymRank;
  final int? strykScore;
  final List<ShareSponsor> sponsors;
  final String displayName;
  final String? profilePhotoPath;
  final int? currentStreak;
  final int? bestStreak;
  /// Verified gym days in the current calendar month.
  final int? verifiedDaysMonth;

  DateTime get time => startTime;

  factory SharePayload.fromRecord(
    DailyRecord record, {
    int? gymRank,
    @Deprecated('Use gymRank') int? monthlyRank,
    List<ShareSponsor> sponsors = const [],
    String displayName = '',
    String? profilePhotoPath,
    int? currentStreak,
    int? bestStreak,
    int? verifiedDaysMonth,
  }) {
    final date = record.calendarDate;
    final start = record.arrivalTime ?? date;
    final end = record.endTime ??
        start.add(record.duration ?? const Duration(minutes: 20));
    final duration = record.duration ?? end.difference(start);
    final safeDuration = duration.isNegative ? Duration.zero : duration;
    return SharePayload(
      dayNumber: record.streakAtPoint ?? 0,
      date: date,
      startTime: start,
      endTime: end,
      duration: safeDuration,
      gymName: record.gymName ?? 'Gym',
      totalGymDays: record.totalGymDaysAtThatTime ?? record.streakAtPoint ?? 0,
      verificationId: record.verificationId ?? 'SK-000000',
      verificationUrl: record.verificationUrl ??
          'https://stryk.app/verify/${record.verificationId ?? 'SK-000000'}',
      photoPath: record.sessionPhotoPath,
      gymRank: gymRank ?? monthlyRank,
      strykScore: safeDuration.inMinutes * 12,
      sponsors: sponsors,
      displayName: displayName,
      profilePhotoPath: profilePhotoPath,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      verifiedDaysMonth: verifiedDaysMonth,
    );
  }

  SharePayload copyWith({
    int? gymRank,
    List<ShareSponsor>? sponsors,
    String? displayName,
    String? profilePhotoPath,
    int? currentStreak,
    int? bestStreak,
    int? verifiedDaysMonth,
    String? photoPath,
    bool clearPhoto = false,
  }) =>
      SharePayload(
        dayNumber: dayNumber,
        date: date,
        startTime: startTime,
        endTime: endTime,
        duration: duration,
        gymName: gymName,
        totalGymDays: totalGymDays,
        verificationId: verificationId,
        verificationUrl: verificationUrl,
        photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
        gymRank: gymRank ?? this.gymRank,
        strykScore: strykScore,
        sponsors: sponsors ?? this.sponsors,
        displayName: displayName ?? this.displayName,
        profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
        currentStreak: currentStreak ?? this.currentStreak,
        bestStreak: bestStreak ?? this.bestStreak,
        verifiedDaysMonth: verifiedDaysMonth ?? this.verifiedDaysMonth,
      );
}
