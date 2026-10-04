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
  });

  final String gymId;
  final SessionStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? securedAt;

  bool get isActive =>
      status == SessionStatus.tracking || status == SessionStatus.secured;

  bool get isSecured =>
      status == SessionStatus.secured || status == SessionStatus.completed;

  bool get isCheckedOut => status == SessionStatus.completed;

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
    bool clearEnd = false,
    bool clearStart = false,
    bool clearSecured = false,
  }) {
    return GymSession(
      gymId: gymId ?? this.gymId,
      status: status ?? this.status,
      startTime: clearStart ? null : (startTime ?? this.startTime),
      endTime: clearEnd ? null : (endTime ?? this.endTime),
      securedAt: clearSecured ? null : (securedAt ?? this.securedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'gymId': gymId,
        'status': status.name,
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'securedAt': securedAt?.toIso8601String(),
      };

  factory GymSession.fromJson(Map<String, dynamic> json) {
    final raw = json['status'] as String? ?? 'idle';
    final status = SessionStatus.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => SessionStatus.idle,
    );
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
    );
  }

  static GymSession idle(String gymId) =>
      GymSession(gymId: gymId, status: SessionStatus.idle);
}
