import '../../../core/utils/geo.dart';

enum DemoPresence { outside, inside }

class LocationSnapshot {
  const LocationSnapshot({
    required this.point,
    required this.presence,
  });

  final GeoPoint point;
  final DemoPresence presence;

  Map<String, dynamic> toJson() => {
        'latitude': point.latitude,
        'longitude': point.longitude,
        'presence': presence.name,
      };

  factory LocationSnapshot.fromJson(Map<String, dynamic> json) {
    return LocationSnapshot(
      point: GeoPoint(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      presence: DemoPresence.values.byName(json['presence'] as String),
    );
  }
}
