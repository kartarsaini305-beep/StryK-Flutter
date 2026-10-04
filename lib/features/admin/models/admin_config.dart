class AdminConfig {
  const AdminConfig({
    this.minStayMinutes = 20,
    this.geofenceRadiusMeters = 40,
    this.gymDetectionEnabled = true,
    this.streakEnabled = true,
    this.maintenanceMode = false,
    this.demoTimeMode = false,
    this.announcement = '',
    this.defaultCardStyle = 'minimal',
    this.cardMinimalEnabled = true,
    this.cardPhotoEnabled = true,
    this.cardAchievementEnabled = true,
  });

  final int minStayMinutes;
  final double geofenceRadiusMeters;
  final bool gymDetectionEnabled;
  final bool streakEnabled;
  final bool maintenanceMode;

  /// DEMO ONLY: 1 real second = 1 simulated minute.
  final bool demoTimeMode;
  final String announcement;
  final String defaultCardStyle;
  final bool cardMinimalEnabled;
  final bool cardPhotoEnabled;
  final bool cardAchievementEnabled;

  Duration get minStay => Duration(minutes: minStayMinutes.clamp(5, 180));

  AdminConfig copyWith({
    int? minStayMinutes,
    double? geofenceRadiusMeters,
    bool? gymDetectionEnabled,
    bool? streakEnabled,
    bool? maintenanceMode,
    bool? demoTimeMode,
    String? announcement,
    String? defaultCardStyle,
    bool? cardMinimalEnabled,
    bool? cardPhotoEnabled,
    bool? cardAchievementEnabled,
  }) {
    return AdminConfig(
      minStayMinutes: minStayMinutes ?? this.minStayMinutes,
      geofenceRadiusMeters: geofenceRadiusMeters ?? this.geofenceRadiusMeters,
      gymDetectionEnabled: gymDetectionEnabled ?? this.gymDetectionEnabled,
      streakEnabled: streakEnabled ?? this.streakEnabled,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      demoTimeMode: demoTimeMode ?? this.demoTimeMode,
      announcement: announcement ?? this.announcement,
      defaultCardStyle: defaultCardStyle ?? this.defaultCardStyle,
      cardMinimalEnabled: cardMinimalEnabled ?? this.cardMinimalEnabled,
      cardPhotoEnabled: cardPhotoEnabled ?? this.cardPhotoEnabled,
      cardAchievementEnabled:
          cardAchievementEnabled ?? this.cardAchievementEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'minStayMinutes': minStayMinutes,
        'geofenceRadiusMeters': geofenceRadiusMeters,
        'gymDetectionEnabled': gymDetectionEnabled,
        'streakEnabled': streakEnabled,
        'maintenanceMode': maintenanceMode,
        'demoTimeMode': demoTimeMode,
        'announcement': announcement,
        'defaultCardStyle': defaultCardStyle,
        'cardMinimalEnabled': cardMinimalEnabled,
        'cardPhotoEnabled': cardPhotoEnabled,
        'cardAchievementEnabled': cardAchievementEnabled,
      };

  factory AdminConfig.fromJson(Map<String, dynamic> json) {
    return AdminConfig(
      minStayMinutes: json['minStayMinutes'] as int? ?? 20,
      geofenceRadiusMeters:
          (json['geofenceRadiusMeters'] as num?)?.toDouble() ?? 40,
      gymDetectionEnabled: json['gymDetectionEnabled'] as bool? ?? true,
      streakEnabled: json['streakEnabled'] as bool? ?? true,
      maintenanceMode: json['maintenanceMode'] as bool? ?? false,
      demoTimeMode: json['demoTimeMode'] as bool? ?? false,
      announcement: json['announcement'] as String? ?? '',
      defaultCardStyle: json['defaultCardStyle'] as String? ?? 'minimal',
      cardMinimalEnabled: json['cardMinimalEnabled'] as bool? ?? true,
      cardPhotoEnabled: json['cardPhotoEnabled'] as bool? ?? true,
      cardAchievementEnabled: json['cardAchievementEnabled'] as bool? ?? true,
    );
  }
}
