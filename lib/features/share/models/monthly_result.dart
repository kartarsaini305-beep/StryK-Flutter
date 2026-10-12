import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyPlace {
  const MonthlyPlace({
    required this.userId,
    required this.displayName,
    required this.verifiedDays,
    this.gymName = '',
    this.gymCity = '',
    this.photoUrl = '',
    this.rank = 0,
  });

  final String userId;
  final String displayName;
  final int verifiedDays;
  final String gymName;
  final String gymCity;
  final String photoUrl;
  final int rank;

  factory MonthlyPlace.fromJson(Map<String, dynamic>? json, {int? rank}) {
    final d = json ?? const {};
    return MonthlyPlace(
      userId: d['userId'] as String? ?? '',
      displayName: d['displayName'] as String? ?? '—',
      verifiedDays: (d['verifiedDays'] as num?)?.toInt() ??
          (d['gymDays'] as num?)?.toInt() ??
          0,
      gymName: d['gymName'] as String? ?? '',
      gymCity: d['gymCity'] as String? ?? '',
      photoUrl: d['photoUrl'] as String? ?? '',
      rank: rank ?? (d['rank'] as num?)?.toInt() ?? 0,
    );
  }

  MonthlyPlace copyWith({int? rank, int? verifiedDays}) => MonthlyPlace(
        userId: userId,
        displayName: displayName,
        verifiedDays: verifiedDays ?? this.verifiedDays,
        gymName: gymName,
        gymCity: gymCity,
        photoUrl: photoUrl,
        rank: rank ?? this.rank,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'verifiedDays': verifiedDays,
        'gymDays': verifiedDays,
        'gymName': gymName,
        'gymCity': gymCity,
        'photoUrl': photoUrl,
        'rank': rank,
      };
}

class SponsorSnapshot {
  const SponsorSnapshot({
    required this.sponsorId,
    required this.name,
    required this.logoUrl,
    this.tagline = '',
  });

  final String sponsorId;
  final String name;
  final String logoUrl;
  final String tagline;

  bool get hasBranding => name.trim().isNotEmpty || logoUrl.trim().isNotEmpty;
  bool get hasLogo => logoUrl.trim().isNotEmpty;

  factory SponsorSnapshot.fromJson(Map<String, dynamic>? json) {
    final d = json ?? const {};
    return SponsorSnapshot(
      sponsorId: d['sponsorId'] as String? ?? d['id'] as String? ?? '',
      name: d['name'] as String? ?? '',
      logoUrl: d['logoUrl'] as String? ?? '',
      tagline: d['tagline'] as String? ?? d['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'sponsorId': sponsorId,
        'name': name,
        'logoUrl': logoUrl,
        'tagline': tagline,
      };
}

/// Immutable historical document: monthlyResults/{YYYY-MM}
class MonthlyResult {
  const MonthlyResult({
    required this.month,
    required this.status,
    required this.topFive,
    this.finalizedAt,
    this.publishedAt,
    this.sponsors = const [],
    this.sponsorSnapshot,
    this.tagline = 'CONSISTENCY WINS.',
  });

  final String month; // YYYY-MM
  /// draft | preview | final | published
  final String status;
  final List<MonthlyPlace> topFive;
  final DateTime? finalizedAt;
  final DateTime? publishedAt;
  /// Preferred multi-sponsor list for the share card.
  final List<SponsorSnapshot> sponsors;
  /// Legacy single sponsor (still read for back-compat).
  final SponsorSnapshot? sponsorSnapshot;
  final String tagline;

  bool get isDraft => status == 'draft' || status == 'preview';
  bool get isFinal => status == 'final' || status == 'published';
  bool get isPublished => status == 'published';

  List<SponsorSnapshot> get effectiveSponsors {
    if (sponsors.isNotEmpty) {
      return sponsors.where((s) => s.hasBranding).toList();
    }
    if (sponsorSnapshot != null && sponsorSnapshot!.hasBranding) {
      return [sponsorSnapshot!];
    }
    return const [];
  }

  MonthlyPlace? get firstPlace => topFive.isEmpty ? null : topFive.first;
  MonthlyPlace? get secondPlace =>
      topFive.length > 1 ? topFive[1] : null;
  MonthlyPlace? get thirdPlace =>
      topFive.length > 2 ? topFive[2] : null;

  String get monthLabel {
    final parts = month.split('-');
    if (parts.length != 2) return month;
    final y = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 1;
    const names = [
      '',
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    final name = (m >= 1 && m <= 12) ? names[m] : month;
    return '$name $y';
  }

  String get monthShort {
    final parts = month.split('-');
    if (parts.length != 2) return month;
    final y = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 1;
    const names = [
      '',
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final name = (m >= 1 && m <= 12) ? names[m] : month;
    return '$name $y';
  }

  factory MonthlyResult.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    DateTime? ts(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return null;
    }

    Map<String, dynamic>? map(dynamic v) =>
        v is Map<String, dynamic> ? v : null;

    List<MonthlyPlace> top = const [];
    final rawTop = d['topFive'];
    if (rawTop is List) {
      top = [
        for (var i = 0; i < rawTop.length && i < 5; i++)
          MonthlyPlace.fromJson(
            rawTop[i] is Map<String, dynamic>
                ? rawTop[i] as Map<String, dynamic>
                : null,
            rank: i + 1,
          ),
      ];
    } else {
      // Back-compat with first/second/third fields.
      final places = <MonthlyPlace>[];
      final f = map(d['firstPlace']);
      final s = map(d['secondPlace']);
      final t = map(d['thirdPlace']);
      if (f != null) places.add(MonthlyPlace.fromJson(f, rank: 1));
      if (s != null) places.add(MonthlyPlace.fromJson(s, rank: 2));
      if (t != null) places.add(MonthlyPlace.fromJson(t, rank: 3));
      top = places;
    }

    List<SponsorSnapshot> sponsors = const [];
    final rawSponsors = d['sponsors'];
    if (rawSponsors is List) {
      sponsors = [
        for (final item in rawSponsors)
          if (item is Map<String, dynamic>) SponsorSnapshot.fromJson(item),
      ].where((s) => s.hasBranding).toList();
    }

    final single = d['sponsorSnapshot'] == null
        ? null
        : SponsorSnapshot.fromJson(map(d['sponsorSnapshot']));

    return MonthlyResult(
      month: d['month'] as String? ?? doc.id,
      status: d['status'] as String? ?? 'draft',
      topFive: top,
      finalizedAt: ts(d['finalizedAt']),
      publishedAt: ts(d['publishedAt']),
      sponsors: sponsors,
      sponsorSnapshot: single,
      tagline: d['tagline'] as String? ?? 'CONSISTENCY WINS.',
    );
  }

  Map<String, dynamic> toJson() => {
        'month': month,
        'status': status,
        'topFive': topFive.map((e) => e.toJson()).toList(),
        if (topFive.isNotEmpty) 'firstPlace': topFive[0].toJson(),
        if (topFive.length > 1) 'secondPlace': topFive[1].toJson(),
        if (topFive.length > 2) 'thirdPlace': topFive[2].toJson(),
        'finalizedAt':
            finalizedAt == null ? null : Timestamp.fromDate(finalizedAt!),
        'publishedAt':
            publishedAt == null ? null : Timestamp.fromDate(publishedAt!),
        'sponsors': effectiveSponsors.map((e) => e.toJson()).toList(),
        'sponsorSnapshot':
            effectiveSponsors.isEmpty ? null : effectiveSponsors.first.toJson(),
        'tagline': tagline,
        'locked': isFinal,
      };
}
