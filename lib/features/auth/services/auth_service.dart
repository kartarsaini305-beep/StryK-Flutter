import '../models/user_profile.dart';

abstract class AuthService {
  Future<void> sendOtp(String phone);

  Future<UserProfile> verifyOtp({
    required String phone,
    required String code,
    UserProfile? existing,
  });
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
