class UserProfile {
  const UserProfile({
    required this.id,
    required this.phone,
    required this.name,
    this.city = '',
    this.goal = '',
    this.photoPath,
  });

  final String id;
  final String phone;
  final String name;
  final String city;
  final String goal;
  final String? photoPath;

  UserProfile copyWith({
    String? id,
    String? phone,
    String? name,
    String? city,
    String? goal,
    String? photoPath,
    bool clearPhoto = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      city: city ?? this.city,
      goal: goal ?? this.goal,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'name': name,
        'city': city,
        'goal': goal,
        'photoPath': photoPath,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      phone: json['phone'] as String,
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      goal: json['goal'] as String? ?? '',
      photoPath: json['photoPath'] as String?,
    );
  }
}
