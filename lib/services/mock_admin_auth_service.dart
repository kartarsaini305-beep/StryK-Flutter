import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../app/config.dart';
import '../features/admin/services/admin_auth_service.dart';

/// Local demo admin auth.
/// Verifies the known admin phone + demo OTP only — no password is stored
/// or compared in client UI. Replace with a real backend challenge later.
class MockAdminAuthService implements AdminAuthService {
  MockAdminAuthService({FlutterSecureStorage? secure})
      : _secure = secure ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secure;

  static const _sessionKey = 'admin_session';

  /// Public identity only (not a secret). Used to route admin login.
  static const adminPhoneNational = '8690763916';
  static const adminEmail = 'kartarsaini305@gmail.com';

  @override
  bool get isAdminPhone => true;

  bool isAdminNumber(String nationalOrE164) {
    final digits = nationalOrE164.replaceAll(RegExp(r'\D'), '');
    return digits == adminPhoneNational ||
        digits.endsWith(adminPhoneNational);
  }

  @override
  Future<void> sendAdminOtp(String phone) async {
    if (!isAdminNumber(phone)) {
      throw const AdminAuthException('This number is not an admin account.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 280));
  }

  @override
  Future<void> verifyAdminOtp({
    required String phone,
    required String code,
  }) async {
    if (!isAdminNumber(phone)) {
      throw const AdminAuthException('This number is not an admin account.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (code != AppConfig.demoOtp) {
      throw const AdminAuthException('Invalid admin code.');
    }
    await _secure.write(key: _sessionKey, value: 'admin-demo');
  }

  @override
  Future<bool> hasAdminSession() async {
    final value = await _secure.read(key: _sessionKey);
    return value != null && value.isNotEmpty;
  }

  @override
  Future<void> clearAdminSession() => _secure.delete(key: _sessionKey);
}
