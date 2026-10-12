import 'package:cloud_firestore/cloud_firestore.dart';

/// Creates/updates `users/{uid}` after phone auth.
///
/// Only writes uid / phoneNumber / timestamps — never wipes other fields.
class UserFirestoreRepository {
  UserFirestoreRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> upsertPhoneUser({
    required String uid,
    required String phoneNumber,
  }) async {
    final doc = _db.collection('users').doc(uid);
    final snap = await doc.get();
    final now = FieldValue.serverTimestamp();

    if (!snap.exists) {
      await doc.set({
        'uid': uid,
        'phoneNumber': phoneNumber,
        'createdAt': now,
        'updatedAt': now,
      });
      return;
    }

    await doc.set(
      {
        'uid': uid,
        'phoneNumber': phoneNumber,
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );
  }
}
