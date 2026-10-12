import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../streak/models/daily_record.dart';
import '../models/monthly_result.dart';

/// Live monthly ranking by verified gym days this calendar month.
///
/// Local-first: always merges the current device user so the board never
/// depends solely on Firestore indexes/rules being perfect.
class MonthlyLeaderboardService {
  MonthlyLeaderboardService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static String monthKey([DateTime? at]) =>
      DateFormat('yyyy-MM').format(at ?? DateTime.now());

  CollectionReference<Map<String, dynamic>> _entries(String month) =>
      _db.collection('monthlyLeaderboard').doc(month).collection('entries');

  static int verifiedDaysForMonth(
    Map<String, DailyRecord> records,
    String month,
  ) {
    return records.values.where((r) {
      if (!r.isCompleted) return false;
      final when = r.arrivalTime ?? r.calendarDate;
      return monthKey(when) == month;
    }).length;
  }

  Future<void> syncUserEntry({
    required String userId,
    required String displayName,
    required int verifiedDays,
    String gymName = '',
    String gymCity = '',
    String photoUrl = '',
    DateTime? at,
  }) async {
    if (userId.isEmpty || verifiedDays <= 0) return;
    final month = monthKey(at);
    try {
      await _entries(month).doc(userId).set({
        'userId': userId,
        'displayName': displayName,
        'verifiedDays': verifiedDays,
        'gymDays': verifiedDays,
        'gymName': gymName,
        'gymCity': gymCity,
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 8));
    } catch (e, st) {
      debugPrint('MonthlyLeaderboardService.syncUserEntry: $e\n$st');
    }
  }

  Future<List<MonthlyPlace>> _fetchRemote(String key, int limit) async {
    try {
      final ordered = await _entries(key)
          .orderBy('verifiedDays', descending: true)
          .limit(limit)
          .get()
          .timeout(const Duration(seconds: 8));
      return [
        for (var i = 0; i < ordered.docs.length; i++)
          MonthlyPlace.fromJson(ordered.docs[i].data(), rank: i + 1),
      ];
    } catch (e) {
      debugPrint('orderBy fetch failed, falling back: $e');
      try {
        final raw = await _entries(key)
            .limit(50)
            .get()
            .timeout(const Duration(seconds: 8));
        final places = raw.docs.map((d) => MonthlyPlace.fromJson(d.data())).toList()
          ..sort((a, b) => b.verifiedDays.compareTo(a.verifiedDays));
        return [
          for (var i = 0; i < places.length && i < limit; i++)
            places[i].copyWith(rank: i + 1),
        ];
      } catch (e2, st) {
        debugPrint('MonthlyLeaderboardService._fetchRemote: $e2\n$st');
        return const [];
      }
    }
  }

  List<MonthlyPlace> _merge({
    required List<MonthlyPlace> remote,
    MonthlyPlace? local,
    required int limit,
    String? gymFilter,
  }) {
    final map = <String, MonthlyPlace>{
      for (final p in remote)
        if (gymFilter == null ||
            gymFilter.isEmpty ||
            p.gymName.toLowerCase() == gymFilter.toLowerCase())
          p.userId: p,
    };
    if (local != null &&
        local.verifiedDays > 0 &&
        (gymFilter == null ||
            gymFilter.isEmpty ||
            local.gymName.toLowerCase() == gymFilter.toLowerCase())) {
      final existing = map[local.userId];
      if (existing == null || local.verifiedDays >= existing.verifiedDays) {
        map[local.userId] = local;
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => b.verifiedDays.compareTo(a.verifiedDays));
    return [
      for (var i = 0; i < list.length && i < limit; i++)
        list[i].copyWith(rank: i + 1),
    ];
  }

  /// Global monthly Top N.
  ///
  /// Fetches a wider remote window then merges/ranks so the local user is not
  /// dropped when they sit outside the raw query limit.
  Future<List<MonthlyPlace>> fetchTop({
    String? month,
    int limit = 5,
    MonthlyPlace? localFallback,
  }) async {
    final key = month ?? monthKey();
    final remote = await _fetchRemote(key, 100);
    return _merge(remote: remote, local: localFallback, limit: limit);
  }

  /// Top N inside a gym (case-insensitive gym name match). Never invents rows.
  Future<List<MonthlyPlace>> fetchGymTop({
    required String gymName,
    String? month,
    int limit = 5,
    MonthlyPlace? localFallback,
  }) async {
    final key = month ?? monthKey();
    final remote = await _fetchRemote(key, 100);
    return _merge(
      remote: remote,
      local: localFallback,
      limit: limit,
      gymFilter: gymName,
    );
  }

  /// Rank inside a specific gym (normal share cards).
  Future<int?> gymRankForUser({
    required String userId,
    required String gymName,
    String? month,
    int? localVerifiedDays,
    String displayName = '',
  }) async {
    if (gymName.trim().isEmpty) return null;
    final uid = userId.isEmpty ? 'local-user' : userId;
    final key = month ?? monthKey();
    final local = localVerifiedDays == null
        ? null
        : MonthlyPlace(
            userId: uid,
            displayName: displayName,
            verifiedDays: localVerifiedDays,
            gymName: gymName,
          );
    final remote = await _fetchRemote(key, 100);
    final board = _merge(
      remote: remote,
      local: local,
      limit: 100,
      gymFilter: gymName,
    );
    for (final p in board) {
      if (p.userId == uid) return p.rank;
    }
    // Solo gym member with verified days → rank #1.
    if (local != null && local.verifiedDays > 0 && board.isEmpty) {
      return 1;
    }
    return null;
  }

  /// Global monthly rank (1-based), or null if unranked.
  Future<int?> rankForUser({
    required String userId,
    String? month,
    int? localVerifiedDays,
    String displayName = '',
    String gymName = '',
  }) async {
    final uid = userId.isEmpty ? 'local-user' : userId;
    final key = month ?? monthKey();
    final local = localVerifiedDays == null
        ? null
        : MonthlyPlace(
            userId: uid,
            displayName: displayName,
            verifiedDays: localVerifiedDays,
            gymName: gymName,
          );
    final top = await fetchTop(month: key, limit: 100, localFallback: local);
    for (final p in top) {
      if (p.userId == uid) return p.rank;
    }
    return null;
  }
}
