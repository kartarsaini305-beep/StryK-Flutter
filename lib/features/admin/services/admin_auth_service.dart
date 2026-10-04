/// Admin auth abstraction. No passwords/secrets live in UI code.
abstract class AdminAuthService {
  bool get isAdminPhone;

  Future<void> sendAdminOtp(String phone);

  Future<void> verifyAdminOtp({
    required String phone,
    required String code,
  });

  Future<bool> hasAdminSession();

  Future<void> clearAdminSession();
}

class AdminAuthException implements Exception {
  const AdminAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
