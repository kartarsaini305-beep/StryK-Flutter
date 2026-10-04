import '../../../core/utils/geo.dart';

class Gym {
  const Gym({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.placeholderLabel,
  });

  final String id;
  final String name;
  final String address;
  final GeoPoint location;
  final String placeholderLabel;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'placeholderLabel': placeholderLabel,
      };

  factory Gym.fromJson(Map<String, dynamic> json) {
    return Gym(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      location: GeoPoint(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      placeholderLabel: json['placeholderLabel'] as String,
    );
  }
}
