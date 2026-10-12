import '../models/user_profile.dart';

abstract class AuthService {
  /// Sends an SMS OTP to [phone] (E.164, e.g. +9198…).
  /// Pass [forceResend] true when the user taps Resend.
  Future<void> sendOtp(String phone, {bool forceResend = false});

  Future<UserProfile> verifyOtp({
    required String phone,
    required String code,
    UserProfile? existing,
  });

  /// Returns the currently signed-in Firebase user as a profile, or null.
  Future<UserProfile?> currentSession();

  Future<void> signOut();
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
