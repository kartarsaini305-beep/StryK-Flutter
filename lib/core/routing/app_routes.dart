abstract final class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const phone = '/phone';
  static const otp = '/otp/:phone';
  static const name = '/name';
  static const selectGym = '/select-gym';
  static const home = '/home';
  static const streak = '/streak';
  static const profile = '/profile';
  static const share = '/share/:dateKey';
  static const sharePreview = '/share/:dateKey/:style';
  static const day = '/day/:dateKey';
  static const verify = '/verify/:verificationId';
  static const adminLogin = '/admin-login';
  static const admin = '/admin';
  static const privacy = '/privacy';
  static const terms = '/terms';

  static String otpFor(String phone) => '/otp/$phone';
  static String shareFor(String dateKey) => '/share/$dateKey';
  static String sharePreviewFor(String dateKey, String style) =>
      '/share/$dateKey/$style';
  static String dayFor(String dateKey) => '/day/$dateKey';
  static String verifyFor(String id) => '/verify/$id';
}
