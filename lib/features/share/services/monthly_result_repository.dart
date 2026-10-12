import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../sponsors/models/sponsor.dart';
import '../models/monthly_result.dart';
import 'monthly_leaderboard_service.dart';

class MonthlyResultRepository {
  MonthlyResultRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final _lb = MonthlyLeaderboardService();

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('monthlyResults');

  static String monthKey([DateTime? at]) =>
      DateFormat('yyyy-MM').format(at ?? DateTime.now());

  static List<SponsorSnapshot> snapshotsFrom(List<Sponsor> sponsors) {
    return [
      for (final s in sponsors)
        SponsorSnapshot(
          sponsorId: s.id,
          name: s.name,
          logoUrl: s.logoUrl,
          tagline: s.description.isNotEmpty ? s.description : s.campaignName,
        ),
    ];
  }

  Future<MonthlyResult?> fetch(String month) async {
    try {
      final doc = await _col.doc(month).get().timeout(const Duration(seconds: 8));
      if (!doc.exists) return null;
      return MonthlyResult.fromDoc(doc);
    } catch (e, st) {
      debugPrint('MonthlyResultRepository.fetch: $e\n$st');
      return null;
    }
  }

  Future<List<MonthlyResult>> fetchPublished({int limit = 24}) async {
    try {
      final snap = await _col
          .orderBy('month', descending: true)
          .limit(limit)
          .get()
          .timeout(const Duration(seconds: 8));
      return snap.docs
          .map(MonthlyResult.fromDoc)
          .where((r) => r.isFinal)
          .toList();
    } catch (e, st) {
      debugPrint('MonthlyResultRepository.fetchPublished: $e\n$st');
      return const [];
    }
  }

  Future<MonthlyResult> saveDraft({
    required String month,
    required List<MonthlyPlace> topFive,
    List<Sponsor> sponsors = const [],
    String tagline = 'CONSISTENCY WINS.',
  }) async {
    final existing = await fetch(month);
    if (existing?.isFinal == true) {
      throw StateError('Month $month is already finalized.');
    }
    final snaps = snapshotsFrom(sponsors);
    final result = MonthlyResult(
      month: month,
      status: 'draft',
      topFive: [
        for (var i = 0; i < topFive.length && i < 5; i++)
          topFive[i].copyWith(rank: i + 1),
      ],
      sponsors: snaps,
      sponsorSnapshot: snaps.isEmpty ? null : snaps.first,
      tagline: tagline,
    );
    await _col.doc(month).set(result.toJson(), SetOptions(merge: true));
    return result;
  }

  Future<MonthlyResult> publishMonth({
    required String month,
    required List<MonthlyPlace> topFive,
    List<Sponsor> sponsors = const [],
    String tagline = 'CONSISTENCY WINS.',
  }) async {
    final existing = await fetch(month);
    if (existing?.isFinal == true) {
      throw StateError('Month $month is already locked.');
    }
    if (topFive.isEmpty) {
      throw StateError('No leaderboard entries to publish.');
    }
    final ranked = [
      for (var i = 0; i < topFive.length && i < 5; i++)
        topFive[i].copyWith(rank: i + 1),
    ];
    final snaps = snapshotsFrom(sponsors);
    final result = MonthlyResult(
      month: month,
      status: 'published',
      topFive: ranked,
      finalizedAt: DateTime.now(),
      publishedAt: DateTime.now(),
      sponsors: snaps,
      sponsorSnapshot: snaps.isEmpty ? null : snaps.first,
      tagline: tagline,
    );
    await _col.doc(month).set({
      ...result.toJson(),
      'finalizedAt': FieldValue.serverTimestamp(),
      'publishedAt': FieldValue.serverTimestamp(),
      'locked': true,
    });
    return result;
  }

  Future<List<MonthlyPlace>> liveTopFive({MonthlyPlace? localFallback}) {
    return _lb.fetchTop(limit: 5, localFallback: localFallback);
  }
}
