class AppSettings {
  const AppSettings({
    this.notificationsEnabled = true,
    this.restDayProtection = true,
    this.arrivalNudges = true,
  });

  final bool notificationsEnabled;
  final bool restDayProtection;
  final bool arrivalNudges;

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? restDayProtection,
    bool? arrivalNudges,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      restDayProtection: restDayProtection ?? this.restDayProtection,
      arrivalNudges: arrivalNudges ?? this.arrivalNudges,
    );
  }

  Map<String, dynamic> toJson() => {
        'notificationsEnabled': notificationsEnabled,
        'restDayProtection': restDayProtection,
        'arrivalNudges': arrivalNudges,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      restDayProtection: json['restDayProtection'] as bool? ?? true,
      arrivalNudges: json['arrivalNudges'] as bool? ??
          json['notificationsEnabled'] as bool? ??
          true,
    );
  }
}
