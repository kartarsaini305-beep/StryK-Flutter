import '../app/config.dart';
import '../features/auth/models/user_profile.dart';
import '../features/auth/services/auth_service.dart';

/// Test/demo fallback. Production uses [FirebasePhoneAuthService].
class MockAuthService implements AuthService {
  @override
  Future<void> sendOtp(String phone, {bool forceResend = false}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Future<UserProfile> verifyOtp({
    required String phone,
    required String code,
    UserProfile? existing,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (code != AppConfig.demoOtp) {
      throw const AuthException('That code doesn’t match.');
    }
    if (existing != null && existing.phone == phone) return existing;
    return UserProfile(
      id: existing?.id ?? 'user-$phone',
      phone: phone,
      name: existing?.name ?? '',
      city: existing?.city ?? '',
      goal: existing?.goal ?? '',
      photoPath: existing?.photoPath,
    );
  }

  @override
  Future<UserProfile?> currentSession() async => null;

  @override
  Future<void> signOut() async {}
}
