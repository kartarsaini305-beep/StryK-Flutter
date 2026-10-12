import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sponsor.dart';

/// Firestore + local fallback so Admin sponsor management works even when
/// Firebase admin claims / storage rules block cloud writes.
class SponsorRepository {
  SponsorRepository({
    FirebaseFirestore? db,
    FirebaseStorage? storage,
  })  : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  static const _localKey = 'stryk_sponsors_v1';

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('sponsors');

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<Sponsor>> _loadLocal() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_localKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          if (item is Map<String, dynamic>) _fromLocalMap(item),
      ]..sort((a, b) => a.slot.compareTo(b.slot));
    } catch (e, st) {
      debugPrint('SponsorRepository._loadLocal: $e\n$st');
      return const [];
    }
  }

  Future<void> _saveLocal(List<Sponsor> sponsors) async {
    final prefs = await _prefs;
    final encoded = jsonEncode([
      for (final s in sponsors) _toLocalMap(s),
    ]);
    await prefs.setString(_localKey, encoded);
  }

  Map<String, dynamic> _toLocalMap(Sponsor s) => {
        'id': s.id,
        'name': s.name,
        'logoUrl': s.logoUrl,
        'tier': s.tier,
        'active': s.active,
        'slot': s.slot,
        'placement': s.placement.id,
        'description': s.description,
        'campaignName': s.campaignName,
        'challenge': s.challenge,
        'offer': s.offer,
        'cta': s.cta,
        'startAt': s.startAt?.toIso8601String(),
        'endAt': s.endAt?.toIso8601String(),
        'gymIds': s.gymIds,
        'allGyms': s.allGyms,
      };

  Sponsor _fromLocalMap(Map<String, dynamic> d) {
    DateTime? parse(dynamic v) {
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return Sponsor(
      id: d['id'] as String? ?? '',
      name: d['name'] as String? ?? 'Sponsor',
      logoUrl: d['logoUrl'] as String? ?? '',
      tier: d['tier'] as String? ?? 'Partner',
      active: d['active'] as bool? ?? false,
      slot: (d['slot'] as num?)?.toInt() ?? 1,
      placement: SponsorPlacementX.parse(d['placement'] as String?),
      description: d['description'] as String? ?? '',
      campaignName: d['campaignName'] as String? ?? '',
      challenge: d['challenge'] as String? ?? '',
      offer: d['offer'] as String? ?? '',
      cta: d['cta'] as String? ?? 'View',
      startAt: parse(d['startAt']),
      endAt: parse(d['endAt']),
      gymIds: ((d['gymIds'] as List?) ?? const []).cast<String>(),
      allGyms: d['allGyms'] as bool? ?? true,
    );
  }

  List<Sponsor> _merge(List<Sponsor> remote, List<Sponsor> local) {
    final map = <String, Sponsor>{
      for (final s in remote) s.id: s,
    };
    for (final s in local) {
      // Local wins on conflict so admin edits always stick on-device.
      map[s.id] = s;
    }
    final list = map.values.toList()
      ..sort((a, b) => a.slot.compareTo(b.slot));
    return list;
  }

  Stream<List<Sponsor>> watchAll() {
    return Stream.fromFuture(fetchAll()).asBroadcastStream();
  }

  Stream<List<Sponsor>> watchActive({String? gymId, int limit = 5}) {
    return Stream.fromFuture(fetchActive(gymId: gymId, limit: limit))
        .asBroadcastStream();
  }

  Future<List<Sponsor>> fetchActive({
    String? gymId,
    int limit = 5,
    SponsorPlacement? placement,
  }) async {
    final all = await fetchAll();
    final now = DateTime.now();
    final list = all
        .where(
          (s) =>
              s.isLiveAt(now) &&
              s.targetsGym(gymId) &&
              (placement == null || s.placement == placement),
        )
        .toList()
      ..sort((a, b) => a.slot.compareTo(b.slot));
    return list.take(limit).toList();
  }

  Future<List<Sponsor>> fetchAll() async {
    final local = await _loadLocal();
    List<Sponsor> remote = const [];
    try {
      final snap = await _col.get().timeout(const Duration(seconds: 8));
      remote = snap.docs.map(Sponsor.fromDoc).toList();
    } catch (e, st) {
      debugPrint('SponsorRepository.fetchAll remote: $e\n$st');
    }
    return _merge(remote, local);
  }

  Future<String> uploadLogo({
    required String sponsorId,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    // Always keep a durable local copy for card rendering.
    final localPath = await _persistLogoLocally(sponsorId: sponsorId, file: file);
    onProgress?.call(0.4);

    try {
      final ext = file.path.split('.').last.toLowerCase();
      final safeExt =
          (ext == 'png' || ext == 'jpg' || ext == 'jpeg' || ext == 'webp')
              ? ext
              : 'jpg';
      final ref = _storage.ref('sponsors/$sponsorId/logo.$safeExt');
      final task = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/$safeExt'),
      );
      task.snapshotEvents.listen((snap) {
        final total = snap.totalBytes;
        if (total > 0 && onProgress != null) {
          onProgress(0.4 + 0.6 * (snap.bytesTransferred / total));
        }
      });
      await task.timeout(const Duration(seconds: 20));
      final url = await ref.getDownloadURL();
      onProgress?.call(1);
      return url;
    } catch (e, st) {
      debugPrint('SponsorRepository.uploadLogo cloud failed, using local: $e\n$st');
      onProgress?.call(1);
      return localPath;
    }
  }

  Future<String> _persistLogoLocally({
    required String sponsorId,
    required File file,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/sponsors');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final ext = file.path.split('.').last.toLowerCase();
    final safeExt =
        (ext == 'png' || ext == 'jpg' || ext == 'jpeg' || ext == 'webp')
            ? ext
            : 'jpg';
    final dest = File('${folder.path}/$sponsorId.$safeExt');
    await file.copy(dest.path);
    return dest.path;
  }

  Future<Sponsor> upsert(Sponsor sponsor) async {
    final id = sponsor.id.isEmpty
        ? 'sp_${DateTime.now().millisecondsSinceEpoch}'
        : sponsor.id;
    final saved = sponsor.copyWith(id: id);

    // Persist locally first so Admin always succeeds.
    final local = await _loadLocal();
    final next = [
      for (final s in local)
        if (s.id != id) s,
      saved,
    ]..sort((a, b) => a.slot.compareTo(b.slot));
    await _saveLocal(next);

    try {
      await _col
          .doc(id)
          .set(saved.toJson(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 8));
    } catch (e, st) {
      debugPrint('SponsorRepository.upsert cloud: $e\n$st');
    }
    return saved;
  }

  Future<void> setActive(String id, bool active) async {
    final local = await _loadLocal();
    final next = [
      for (final s in local)
        if (s.id == id) s.copyWith(active: active) else s,
    ];
    // If not in local yet, pull from merged list.
    if (!next.any((s) => s.id == id)) {
      final all = await fetchAll();
      final found = all.where((s) => s.id == id).toList();
      if (found.isNotEmpty) {
        next.add(found.first.copyWith(active: active));
      }
    }
    await _saveLocal(next);
    try {
      await _col
          .doc(id)
          .set({'active': active}, SetOptions(merge: true))
          .timeout(const Duration(seconds: 8));
    } catch (e, st) {
      debugPrint('SponsorRepository.setActive cloud: $e\n$st');
    }
  }

  Future<void> reorder(String id, int newSlot) async {
    final all = await fetchAll();
    final updated = [
      for (final s in all)
        if (s.id == id) s.copyWith(slot: newSlot) else s,
    ]..sort((a, b) => a.slot.compareTo(b.slot));
    await _saveLocal(updated);
    try {
      await _col
          .doc(id)
          .set({'slot': newSlot, 'sortOrder': newSlot}, SetOptions(merge: true))
          .timeout(const Duration(seconds: 8));
    } catch (e, st) {
      debugPrint('SponsorRepository.reorder cloud: $e\n$st');
    }
  }

  Future<void> moveSlot(String id, {required bool earlier}) async {
    final all = await fetchAll();
    final idx = all.indexWhere((s) => s.id == id);
    if (idx < 0) return;
    final swapWith = earlier ? idx - 1 : idx + 1;
    if (swapWith < 0 || swapWith >= all.length) return;
    final a = all[idx];
    final b = all[swapWith];
    final aSlot = a.slot;
    final bSlot = b.slot;
    // If slots equal, assign sequential.
    final newA = bSlot == aSlot ? (earlier ? aSlot - 1 : aSlot + 1) : bSlot;
    final newB = bSlot == aSlot ? aSlot : aSlot;
    await upsert(a.copyWith(slot: newA));
    await upsert(b.copyWith(slot: newB));
  }

  Future<void> delete(String id) async {
    final local = await _loadLocal();
    await _saveLocal([for (final s in local) if (s.id != id) s]);
    try {
      await _col.doc(id).delete().timeout(const Duration(seconds: 8));
    } catch (e, st) {
      debugPrint('SponsorRepository.delete cloud: $e\n$st');
    }
    try {
      await _storage.ref('sponsors/$id').listAll().then((res) async {
        for (final item in res.items) {
          await item.delete();
        }
      });
    } catch (_) {
      // Storage cleanup is best-effort.
    }
  }
}
