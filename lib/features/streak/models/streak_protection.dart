class StreakProtection {
  const StreakProtection({
    this.bankedSaves = 0,
    this.lastSaveEarnedAtTotal = 0,
  });

  final int bankedSaves;
  final int lastSaveEarnedAtTotal;

  StreakProtection copyWith({int? bankedSaves, int? lastSaveEarnedAtTotal}) {
    return StreakProtection(
      bankedSaves: bankedSaves ?? this.bankedSaves,
      lastSaveEarnedAtTotal: lastSaveEarnedAtTotal ?? this.lastSaveEarnedAtTotal,
    );
  }

  Map<String, dynamic> toJson() => {
        'bankedSaves': bankedSaves,
        'lastSaveEarnedAtTotal': lastSaveEarnedAtTotal,
      };

  factory StreakProtection.fromJson(Map<String, dynamic> json) {
    return StreakProtection(
      bankedSaves: json['bankedSaves'] as int? ?? 0,
      lastSaveEarnedAtTotal: json['lastSaveEarnedAtTotal'] as int? ?? 0,
    );
  }
}
