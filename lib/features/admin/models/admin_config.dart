class AdminConfig {
  const AdminConfig({
    this.minStayMinutes = 20,
    this.checkInRadiusMeters = 40,
    this.checkOutRadiusMeters = 50,
    this.outsideDurationMinutes = 5,
    this.gymDetectionEnabled = true,
    this.streakEnabled = true,
    this.maintenanceMode = false,
    this.demoTimeMode = false,
    this.announcement = '',
    this.defaultCardStyle = 'minimal',
    this.cardMinimalEnabled = true,
    this.cardPhotoEnabled = true,
    this.cardAchievementEnabled = true,
    this.gymNameOverride = '',
    this.gymLatitude,
    this.gymLongitude,
  });

  final int minStayMinutes;
  final double checkInRadiusMeters;
  final double checkOutRadiusMeters;
  final int outsideDurationMinutes;
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
  final String gymNameOverride;
  final double? gymLatitude;
  final double? gymLongitude;

  Duration get minStay => Duration(minutes: minStayMinutes.clamp(5, 180));
  Duration get outsideDuration =>
      Duration(minutes: outsideDurationMinutes.clamp(1, 30));

  /// Backward-compatible alias used across the app.
  double get geofenceRadiusMeters => checkInRadiusMeters;

  AdminConfig copyWith({
    int? minStayMinutes,
    double? checkInRadiusMeters,
    double? checkOutRadiusMeters,
    int? outsideDurationMinutes,
    bool? gymDetectionEnabled,
    bool? streakEnabled,
    bool? maintenanceMode,
    bool? demoTimeMode,
    String? announcement,
    String? defaultCardStyle,
    bool? cardMinimalEnabled,
    bool? cardPhotoEnabled,
    bool? cardAchievementEnabled,
    String? gymNameOverride,
    double? gymLatitude,
    double? gymLongitude,
    bool clearGymCoords = false,
  }) {
    return AdminConfig(
      minStayMinutes: minStayMinutes ?? this.minStayMinutes,
      checkInRadiusMeters: checkInRadiusMeters ?? this.checkInRadiusMeters,
      checkOutRadiusMeters: checkOutRadiusMeters ?? this.checkOutRadiusMeters,
      outsideDurationMinutes:
          outsideDurationMinutes ?? this.outsideDurationMinutes,
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
      gymNameOverride: gymNameOverride ?? this.gymNameOverride,
      gymLatitude: clearGymCoords ? null : (gymLatitude ?? this.gymLatitude),
      gymLongitude:
          clearGymCoords ? null : (gymLongitude ?? this.gymLongitude),
    );
  }

  Map<String, dynamic> toJson() => {
        'minStayMinutes': minStayMinutes,
        'checkInRadiusMeters': checkInRadiusMeters,
        'geofenceRadiusMeters': checkInRadiusMeters,
        'checkOutRadiusMeters': checkOutRadiusMeters,
        'outsideDurationMinutes': outsideDurationMinutes,
        'gymDetectionEnabled': gymDetectionEnabled,
        'streakEnabled': streakEnabled,
        'maintenanceMode': maintenanceMode,
        'demoTimeMode': demoTimeMode,
        'announcement': announcement,
        'defaultCardStyle': defaultCardStyle,
        'cardMinimalEnabled': cardMinimalEnabled,
        'cardPhotoEnabled': cardPhotoEnabled,
        'cardAchievementEnabled': cardAchievementEnabled,
        'gymNameOverride': gymNameOverride,
        'gymLatitude': gymLatitude,
        'gymLongitude': gymLongitude,
      };

  factory AdminConfig.fromJson(Map<String, dynamic> json) {
    final checkIn = (json['checkInRadiusMeters'] as num?)?.toDouble() ??
        (json['geofenceRadiusMeters'] as num?)?.toDouble() ??
        40;
    return AdminConfig(
      minStayMinutes: json['minStayMinutes'] as int? ?? 20,
      checkInRadiusMeters: checkIn,
      checkOutRadiusMeters:
          (json['checkOutRadiusMeters'] as num?)?.toDouble() ?? 50,
      outsideDurationMinutes: json['outsideDurationMinutes'] as int? ?? 5,
      gymDetectionEnabled: json['gymDetectionEnabled'] as bool? ?? true,
      streakEnabled: json['streakEnabled'] as bool? ?? true,
      maintenanceMode: json['maintenanceMode'] as bool? ?? false,
      demoTimeMode: json['demoTimeMode'] as bool? ?? false,
      announcement: json['announcement'] as String? ?? '',
      defaultCardStyle: json['defaultCardStyle'] as String? ?? 'minimal',
      cardMinimalEnabled: json['cardMinimalEnabled'] as bool? ?? true,
      cardPhotoEnabled: json['cardPhotoEnabled'] as bool? ?? true,
      cardAchievementEnabled: json['cardAchievementEnabled'] as bool? ?? true,
      gymNameOverride: json['gymNameOverride'] as String? ?? '',
      gymLatitude: (json['gymLatitude'] as num?)?.toDouble(),
      gymLongitude: (json['gymLongitude'] as num?)?.toDouble(),
    );
  }
}
