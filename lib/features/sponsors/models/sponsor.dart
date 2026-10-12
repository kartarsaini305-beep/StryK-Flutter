import 'package:cloud_firestore/cloud_firestore.dart';

/// Where a sponsor appears — three separate pools.
enum SponsorPlacement {
  /// Home / in-app surfaces.
  app,

  /// Normal daily shareable cards.
  dailyCard,

  /// Monthly Top 5 shareable card.
  monthlyCard,
}

extension SponsorPlacementX on SponsorPlacement {
  String get id => switch (this) {
        SponsorPlacement.app => 'app',
        SponsorPlacement.dailyCard => 'dailyCard',
        SponsorPlacement.monthlyCard => 'monthlyCard',
      };

  String get label => switch (this) {
        SponsorPlacement.app => 'App',
        SponsorPlacement.dailyCard => 'Daily card',
        SponsorPlacement.monthlyCard => 'Monthly card',
      };

  static SponsorPlacement parse(String? raw) {
    return switch (raw) {
      'dailyCard' || 'daily' => SponsorPlacement.dailyCard,
      'monthlyCard' || 'monthly' => SponsorPlacement.monthlyCard,
      _ => SponsorPlacement.app,
    };
  }
}

class Sponsor {
  const Sponsor({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.tier,
    required this.active,
    required this.slot,
    this.placement = SponsorPlacement.app,
    this.description = '',
    this.campaignName = '',
    this.challenge = '',
    this.offer = '',
    this.cta = 'View',
    this.startAt,
    this.endAt,
    this.gymIds = const [],
    this.allGyms = true,
  });

  final String id;
  final String name;
  final String logoUrl;
  final String tier;
  final bool active;
  final int slot;
  final SponsorPlacement placement;
  final String description;
  final String campaignName;
  final String challenge;
  final String offer;
  final String cta;
  final DateTime? startAt;
  final DateTime? endAt;
  final List<String> gymIds;
  final bool allGyms;

  bool isLiveAt(DateTime now) {
    if (!active) return false;
    if (startAt != null && now.isBefore(startAt!)) return false;
    if (endAt != null && now.isAfter(endAt!)) return false;
    return true;
  }

  bool targetsGym(String? gymId) {
    if (allGyms) return true;
    if (gymId == null) return false;
    return gymIds.contains(gymId);
  }

  factory Sponsor.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    DateTime? ts(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return Sponsor(
      id: doc.id,
      name: d['name'] as String? ?? 'Sponsor',
      logoUrl: d['logoUrl'] as String? ?? '',
      tier: d['tier'] as String? ?? 'Partner',
      active: d['active'] as bool? ?? false,
      slot: (d['slot'] as num?)?.toInt() ??
          (d['sortOrder'] as num?)?.toInt() ??
          1,
      placement: SponsorPlacementX.parse(d['placement'] as String?),
      description: d['description'] as String? ?? '',
      campaignName: d['campaignName'] as String? ?? '',
      challenge: d['challenge'] as String? ?? '',
      offer: d['offer'] as String? ?? '',
      cta: d['cta'] as String? ?? 'View',
      startAt: ts(d['startAt']),
      endAt: ts(d['endAt']),
      gymIds: ((d['gymIds'] as List?) ?? const []).cast<String>(),
      allGyms: d['allGyms'] as bool? ?? true,
    );
  }

  Sponsor copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? tier,
    bool? active,
    int? slot,
    SponsorPlacement? placement,
    String? description,
    String? campaignName,
    String? challenge,
    String? offer,
    String? cta,
    DateTime? startAt,
    DateTime? endAt,
    List<String>? gymIds,
    bool? allGyms,
    bool clearStart = false,
    bool clearEnd = false,
  }) {
    return Sponsor(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      tier: tier ?? this.tier,
      active: active ?? this.active,
      slot: slot ?? this.slot,
      placement: placement ?? this.placement,
      description: description ?? this.description,
      campaignName: campaignName ?? this.campaignName,
      challenge: challenge ?? this.challenge,
      offer: offer ?? this.offer,
      cta: cta ?? this.cta,
      startAt: clearStart ? null : (startAt ?? this.startAt),
      endAt: clearEnd ? null : (endAt ?? this.endAt),
      gymIds: gymIds ?? this.gymIds,
      allGyms: allGyms ?? this.allGyms,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'logoUrl': logoUrl,
        'tier': tier,
        'active': active,
        'slot': slot,
        'sortOrder': slot,
        'placement': placement.id,
        'description': description,
        'campaignName': campaignName,
        'challenge': challenge,
        'offer': offer,
        'cta': cta,
        'startAt': startAt == null ? null : Timestamp.fromDate(startAt!),
        'endAt': endAt == null ? null : Timestamp.fromDate(endAt!),
        'gymIds': gymIds,
        'allGyms': allGyms,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> toSnapshot() => {
        'sponsorId': id,
        'id': id,
        'name': name,
        'logoUrl': logoUrl,
        'tier': tier,
        'placement': placement.id,
      };
}
