import '../app/config.dart';
import '../features/auth/models/user_profile.dart';
import '../features/auth/services/auth_service.dart';

class MockAuthService implements AuthService {
  @override
  Future<void> sendOtp(String phone) async {
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
      id: 'user-$phone',
      phone: phone,
      name: existing?.name ?? '',
    );
  }
}
