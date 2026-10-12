import '../../../core/utils/dates.dart';
import '../../../core/utils/geo.dart';

enum SessionStatus {
  idle,
  tracking,
  secured,
  interrupted,
  completed,
}

class GymSession {
  const GymSession({
    required this.gymId,
    required this.status,
    this.startTime,
    this.endTime,
    this.securedAt,
    this.checkInPoint,
    this.leftZoneAt,
  });

  final String gymId;
  final SessionStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? securedAt;
  final GeoPoint? checkInPoint;
  final DateTime? leftZoneAt;

  bool get isActive =>
      status == SessionStatus.tracking || status == SessionStatus.secured;

  bool get isSecured =>
      status == SessionStatus.secured || status == SessionStatus.completed;

  bool get isCheckedOut => status == SessionStatus.completed;

  /// Whether this session belongs to [wall]'s local calendar day.
  /// Idle shells with no start time are treated as the current day.
  bool belongsToLocalDay(DateTime wall) {
    final start = startTime;
    if (start == null) return status == SessionStatus.idle;
    return Dates.isSameDay(start, wall);
  }

  Duration elapsed([DateTime? now]) {
    final start = startTime;
    if (start == null) return Duration.zero;
    final end = endTime ?? now ?? DateTime.now();
    final value = end.difference(start);
    return value.isNegative ? Duration.zero : value;
  }

  GymSession copyWith({
    String? gymId,
    SessionStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? securedAt,
    GeoPoint? checkInPoint,
    DateTime? leftZoneAt,
    bool clearEnd = false,
    bool clearStart = false,
    bool clearSecured = false,
    bool clearCheckIn = false,
    bool clearLeftZone = false,
  }) {
    return GymSession(
      gymId: gymId ?? this.gymId,
      status: status ?? this.status,
      startTime: clearStart ? null : (startTime ?? this.startTime),
      endTime: clearEnd ? null : (endTime ?? this.endTime),
      securedAt: clearSecured ? null : (securedAt ?? this.securedAt),
      checkInPoint: clearCheckIn ? null : (checkInPoint ?? this.checkInPoint),
      leftZoneAt: clearLeftZone ? null : (leftZoneAt ?? this.leftZoneAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'gymId': gymId,
        'status': status.name,
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'securedAt': securedAt?.toIso8601String(),
        'checkInLat': checkInPoint?.latitude,
        'checkInLng': checkInPoint?.longitude,
        'leftZoneAt': leftZoneAt?.toIso8601String(),
      };

  factory GymSession.fromJson(Map<String, dynamic> json) {
    final raw = json['status'] as String? ?? 'idle';
    final status = SessionStatus.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => SessionStatus.idle,
    );
    final lat = (json['checkInLat'] as num?)?.toDouble();
    final lng = (json['checkInLng'] as num?)?.toDouble();
    return GymSession(
      gymId: json['gymId'] as String,
      status: status,
      startTime: json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      securedAt: json['securedAt'] == null
          ? null
          : DateTime.parse(json['securedAt'] as String),
      checkInPoint: lat != null && lng != null ? GeoPoint(lat, lng) : null,
      leftZoneAt: json['leftZoneAt'] == null
          ? null
          : DateTime.parse(json['leftZoneAt'] as String),
    );
  }

  static GymSession idle(String gymId) =>
      GymSession(gymId: gymId, status: SessionStatus.idle);
}
