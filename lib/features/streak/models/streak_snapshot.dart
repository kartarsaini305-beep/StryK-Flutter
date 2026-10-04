class StreakSnapshot {
  const StreakSnapshot({
    this.current = 0,
    this.best = 0,
    this.totalGymDays = 0,
  });

  final int current;
  final int best;
  final int totalGymDays;

  StreakSnapshot copyWith({int? current, int? best, int? totalGymDays}) {
    return StreakSnapshot(
      current: current ?? this.current,
      best: best ?? this.best,
      totalGymDays: totalGymDays ?? this.totalGymDays,
    );
  }

  Map<String, dynamic> toJson() => {
        'current': current,
        'best': best,
        'totalGymDays': totalGymDays,
      };

  factory StreakSnapshot.fromJson(Map<String, dynamic> json) {
    return StreakSnapshot(
      current: json['current'] as int? ?? 0,
      best: json['best'] as int? ?? 0,
      totalGymDays: json['totalGymDays'] as int? ?? 0,
    );
  }
}
