abstract final class AppConfig {
  static const isDemoMode = true;
  static const demoOtp = '123456';
  static const countryCode = '+91';
  static const geofenceRadiusMeters = 40.0;
  static const sessionDuration = Duration(minutes: 20);
  static const detectionWindow = Duration(milliseconds: 1400);
  static const otpResend = Duration(seconds: 30);
  static const phoneLength = 10;
}
