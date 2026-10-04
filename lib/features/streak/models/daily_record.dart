enum DayKind { completed, sundayProtected, streakSaved, missed, none }

class DailyRecord {
  const DailyRecord({
    required this.dateKey,
    required this.kind,
    this.id,
    this.gymId,
    this.gymName,
    this.arrivalTime,
    this.endTime,
    this.duration,
    this.streakAtPoint,
    this.totalGymDaysAtThatTime,
    this.verificationId,
    this.verificationUrl,
    this.wasSundayProtected = false,
    this.wasStreakSaved = false,
    this.optionalPhotoPath,
    this.cardStyle,
  });

  final String dateKey;
  final DayKind kind;
  final String? id;
  final String? gymId;
  final String? gymName;
  final DateTime? arrivalTime;
  final DateTime? endTime;
  final Duration? duration;
  final int? streakAtPoint;
  final int? totalGymDaysAtThatTime;
  final String? verificationId;
  final String? verificationUrl;
  final bool wasSundayProtected;
  final bool wasStreakSaved;
  final String? optionalPhotoPath;
  final String? cardStyle;

  bool get isCompleted => kind == DayKind.completed;

  DateTime get calendarDate => DateTime.parse(dateKey);

  DailyRecord copyWith({
    String? id,
    String? dateKey,
    DayKind? kind,
    String? gymId,
    String? gymName,
    DateTime? arrivalTime,
    DateTime? endTime,
    Duration? duration,
    int? streakAtPoint,
    int? totalGymDaysAtThatTime,
    String? verificationId,
    String? verificationUrl,
    bool? wasSundayProtected,
    bool? wasStreakSaved,
    String? optionalPhotoPath,
    String? cardStyle,
    bool clearPhoto = false,
  }) {
    return DailyRecord(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      kind: kind ?? this.kind,
      gymId: gymId ?? this.gymId,
      gymName: gymName ?? this.gymName,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      streakAtPoint: streakAtPoint ?? this.streakAtPoint,
      totalGymDaysAtThatTime:
          totalGymDaysAtThatTime ?? this.totalGymDaysAtThatTime,
      verificationId: verificationId ?? this.verificationId,
      verificationUrl: verificationUrl ?? this.verificationUrl,
      wasSundayProtected: wasSundayProtected ?? this.wasSundayProtected,
      wasStreakSaved: wasStreakSaved ?? this.wasStreakSaved,
      optionalPhotoPath:
          clearPhoto ? null : (optionalPhotoPath ?? this.optionalPhotoPath),
      cardStyle: cardStyle ?? this.cardStyle,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'kind': kind.name,
        'gymId': gymId,
        'gymName': gymName,
        'arrivalTime': arrivalTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'durationMs': duration?.inMilliseconds,
        'streakAtPoint': streakAtPoint,
        'totalGymDaysAtThatTime': totalGymDaysAtThatTime,
        'verificationId': verificationId,
        'verificationUrl': verificationUrl,
        'wasSundayProtected': wasSundayProtected,
        'wasStreakSaved': wasStreakSaved,
        'optionalPhotoPath': optionalPhotoPath,
        'cardStyle': cardStyle,
      };

  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    return DailyRecord(
      id: json['id'] as String?,
      dateKey: json['dateKey'] as String,
      kind: DayKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => DayKind.none,
      ),
      gymId: json['gymId'] as String?,
      gymName: json['gymName'] as String?,
      arrivalTime: _date(json['arrivalTime']),
      endTime: _date(json['endTime']),
      duration: json['durationMs'] == null
          ? null
          : Duration(milliseconds: json['durationMs'] as int),
      streakAtPoint: json['streakAtPoint'] as int?,
      totalGymDaysAtThatTime: json['totalGymDaysAtThatTime'] as int?,
      verificationId: json['verificationId'] as String?,
      verificationUrl: json['verificationUrl'] as String?,
      wasSundayProtected: json['wasSundayProtected'] as bool? ?? false,
      wasStreakSaved: json['wasStreakSaved'] as bool? ?? false,
      optionalPhotoPath: json['optionalPhotoPath'] as String?,
      cardStyle: json['cardStyle'] as String?,
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.parse(value);
  }
}
