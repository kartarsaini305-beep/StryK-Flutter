import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../features/auth/models/user_profile.dart';
import '../features/auth/services/auth_service.dart';
import 'user_firestore_repository.dart';

/// Firebase Phone Authentication (official SMS flow).
///
/// ## Firebase Console (manual) — required for SMS to India (+91)
/// 1. Authentication → Sign-in method → enable **Phone**.
/// 2. Authentication → Settings → **SMS region policy** → Allow → include **India**.
///    (`operation-not-allowed` / "This operation is not allowed…" is usually this,
///    even when the Phone provider toggle is already ON.)
/// 3. Project must be on **Blaze** (Phone SMS is not available on Spark).
/// 4. Project settings → Android app `com.stryk.stryk` → add **SHA-1** + **SHA-256**,
///    then re-download `google-services.json` (oauth_client must not stay empty).
///    Debug SHA-1: `C3:58:45:59:63:20:3E:7D:51:9E:85:91:A8:A7:3B:F7:0F:7E:2C:BA`
/// 5. Optional: Authentication → Phone → Phone numbers for testing.
/// 6. Firestore rules for `users/{uid}` (separate from Phone Auth SMS).
class FirebasePhoneAuthService implements AuthService {
  FirebasePhoneAuthService({
    FirebaseAuth? auth,
    UserFirestoreRepository? users,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _users = users ?? UserFirestoreRepository();

  final FirebaseAuth _auth;
  final UserFirestoreRepository _users;

  String? _verificationId;
  int? _forceResendingToken;
  PhoneAuthCredential? _autoCredential;
  String? _lastPhoneE164;

  @override
  Future<void> sendOtp(String phone, {bool forceResend = false}) async {
    final e164 = normalizeIndianE164(phone);
    _lastPhoneE164 = e164;
    _autoCredential = null;

    final completer = Completer<void>();

    await _auth.verifyPhoneNumber(
      phoneNumber: e164,
      timeout: const Duration(seconds: 60),
      forceResendingToken: forceResend ? _forceResendingToken : null,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Android instant verification / auto-retrieval.
        _autoCredential = credential;
        try {
          await _auth.signInWithCredential(credential);
        } catch (_) {
          // User can still enter the SMS code manually.
        }
        if (!completer.isCompleted) completer.complete();
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint(
          'Firebase PhoneAuth verificationFailed '
          'code=${e.code} message=${e.message}',
        );
        if (!completer.isCompleted) {
          completer.completeError(AuthException(_mapFirebaseError(e)));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _forceResendingToken = resendToken;
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );

    return completer.future;
  }

  @override
  Future<UserProfile> verifyOtp({
    required String phone,
    required String code,
    UserProfile? existing,
  }) async {
    final e164 = normalizeIndianE164(phone);
    final current = _auth.currentUser;

    // Instant verification may already have signed the user in.
    if (current != null &&
        current.phoneNumber != null &&
        normalizeIndianE164(current.phoneNumber!) == e164) {
      return _finalize(current, existing: existing);
    }

    final PhoneAuthCredential credential;
    if (_autoCredential != null) {
      credential = _autoCredential!;
      _autoCredential = null;
    } else {
      final verificationId = _verificationId;
      if (verificationId == null || verificationId.isEmpty) {
        throw const AuthException(
          'Code expired or session lost. Request a new OTP.',
        );
      }
      if (code.trim().length != 6) {
        throw const AuthException('Enter the 6-digit code.');
      }
      credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code.trim(),
      );
    }

    try {
      // Changing phone while already signed in → updatePhoneNumber.
      if (current != null &&
          existing != null &&
          current.phoneNumber != null &&
          normalizeIndianE164(current.phoneNumber!) != e164) {
        await current.updatePhoneNumber(credential);
        await current.reload();
        final refreshed = _auth.currentUser;
        if (refreshed == null) {
          throw const AuthException('Could not update phone. Try again.');
        }
        return await _finalize(refreshed, existing: existing);
      }

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) {
        throw const AuthException('Sign-in failed. Try again.');
      }
      return await _finalize(user, existing: existing);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    }
  }

  @override
  Future<UserProfile?> currentSession() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserProfile(
      id: user.uid,
      phone: user.phoneNumber ?? _lastPhoneE164 ?? '',
      name: '',
    );
  }

  @override
  Future<void> signOut() async {
    _verificationId = null;
    _forceResendingToken = null;
    _autoCredential = null;
    _lastPhoneE164 = null;
    await _auth.signOut();
  }

  Future<UserProfile> _finalize(
    User user, {
    UserProfile? existing,
  }) async {
    final phone = user.phoneNumber ?? _lastPhoneE164 ?? existing?.phone ?? '';
    await _users.upsertPhoneUser(uid: user.uid, phoneNumber: phone);

    if (existing != null &&
        (existing.id == user.uid ||
            normalizeIndianE164(existing.phone) == normalizeIndianE164(phone))) {
      return existing.copyWith(id: user.uid, phone: phone);
    }

    return UserProfile(
      id: user.uid,
      phone: phone,
      name: existing?.name ?? '',
      city: existing?.city ?? '',
      goal: existing?.goal ?? '',
      photoPath: existing?.photoPath,
    );
  }

  /// Maps Firebase Auth errors to short, user-facing copy.
  static String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'That mobile number looks invalid.';
      case 'missing-phone-number':
        return 'Enter your mobile number.';
      case 'operation-not-allowed':
        // Common when Phone is "enabled" but SMS region (e.g. India) is blocked,
        // or the project is still on Spark without SMS entitlement.
        final detail = e.message ?? '';
        if (detail.toLowerCase().contains('region')) {
          return 'SMS for this country is blocked. In Firebase Console → '
              'Authentication → Settings → SMS region policy, Allow India.';
        }
        return 'Phone sign-in blocked by Firebase. Enable Phone auth, allow '
            'India in SMS region policy, and use a Blaze project.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a bit and try again.';
      case 'quota-exceeded':
        return 'SMS limit reached. Try again later.';
      case 'session-expired':
      case 'code-expired':
        return 'This code expired. Request a new OTP.';
      case 'invalid-verification-code':
      case 'invalid-verification-id':
        return 'That code doesn’t match. Try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'app-not-authorized':
      case 'missing-client-identifier':
        return 'App not authorized for Phone Auth. Add Android SHA-1/SHA-256 '
            'in Firebase project settings, then re-download google-services.json.';
      case 'captcha-check-failed':
      case 'web-context-cancelled':
        return 'Verification was cancelled. Try again.';
      case 'credential-already-in-use':
        return 'This number is already linked to another account.';
      default:
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'Something went wrong. Try again.';
    }
  }
}

/// Normalizes Indian mobiles to E.164 (+91XXXXXXXXXX).
String normalizeIndianE164(String raw) {
  final trimmed = raw.trim();
  if (trimmed.startsWith('+') && trimmed.length >= 12) {
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) return '+$digits';
    if (digits.length == 10) return '+91$digits';
    return '+$digits';
  }
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) return '+91$digits';
  if (digits.length == 12 && digits.startsWith('91')) return '+$digits';
  if (digits.length == 11 && digits.startsWith('0')) {
    return '+91${digits.substring(1)}';
  }
  return digits.isEmpty ? trimmed : '+$digits';
}
