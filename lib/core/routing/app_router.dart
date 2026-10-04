import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/phone_screen.dart';
import '../../features/gyms/presentation/select_gym_screen.dart';
import '../../features/onboarding/presentation/name_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/profile/presentation/legal_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/session/presentation/home_screen.dart';
import '../../features/admin/presentation/admin_login_screen.dart';
import '../../features/admin/presentation/admin_panel_screen.dart';
import '../../features/share/presentation/choose_card_screen.dart';
import '../../features/share/presentation/share_preview_screen.dart';
import '../../features/share/presentation/verification_screen.dart';
import '../../features/streak/presentation/day_detail_screen.dart';
import '../../features/streak/presentation/streak_screen.dart';
import '../../providers/app_controller.dart';
import '../../providers/app_state.dart';
import '../constants/app_durations.dart';
import '../widgets/app_shell.dart';
import 'app_routes.dart';

CustomTransitionPage<void> _fadePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppDurations.pageFade,
    reverseTransitionDuration: AppDurations.pageFade,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: child,
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen<AppState>(appControllerProvider, (previous, next) {
    if (previous?.ready != next.ready ||
        previous?.authenticated != next.authenticated ||
        previous?.hasName != next.hasName ||
        previous?.hasGym != next.hasGym) {
      refresh.value++;
    }
  });
  ref.onDispose(refresh.dispose);
  return createAppRouter(ref, refresh);
});

GoRouter createAppRouter(Ref ref, Listenable refresh) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final app = ref.read(appControllerProvider);
      final loc = state.uri.path;
      const public = {
        AppRoutes.splash,
        AppRoutes.welcome,
        AppRoutes.phone,
      };

      if (loc == AppRoutes.splash) return null;
      if (!app.ready) return AppRoutes.splash;

      final isOtp = loc.startsWith('/otp');
      final isVerify = loc.startsWith('/verify');
      final isAdmin = loc == AppRoutes.admin || loc == AppRoutes.adminLogin;
      if (isAdmin) {
        if (loc == AppRoutes.admin && !app.adminAuthenticated) {
          return AppRoutes.adminLogin;
        }
        return null;
      }
      if (!app.authenticated) {
        if (public.contains(loc) || isOtp || isVerify) return null;
        return AppRoutes.welcome;
      }

      if (loc == AppRoutes.welcome || loc == AppRoutes.phone) {
        return destinationFor(app);
      }
      if (app.hasName && loc == AppRoutes.name) {
        return app.hasGym ? AppRoutes.home : AppRoutes.selectGym;
      }
      if (!app.hasName && loc != AppRoutes.name && !isOtp && !isVerify) {
        return AppRoutes.name;
      }
      if (app.hasName && !app.hasGym && loc != AppRoutes.selectGym) {
        return AppRoutes.selectGym;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const WelcomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.phone,
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const PhoneScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminLogin,
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const AdminLoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.admin,
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const AdminPanelScreen()),
      ),
      GoRoute(
        path: AppRoutes.otp,
        pageBuilder: (context, state) {
          final phone = state.pathParameters['phone'] ?? '';
          return _fadePage(
            state: state,
            child: OtpScreen(nationalNumber: phone),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.name,
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const NameScreen()),
      ),
      GoRoute(
        path: AppRoutes.selectGym,
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const SelectGymScreen()),
      ),
      GoRoute(
        path: AppRoutes.sharePreview,
        pageBuilder: (context, state) {
          final dateKey = state.pathParameters['dateKey'] ?? '';
          final style = state.pathParameters['style'] ?? 'minimal';
          return _fadePage(
            state: state,
            child: SharePreviewScreen(dateKey: dateKey, styleName: style),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.share,
        pageBuilder: (context, state) {
          final dateKey = state.pathParameters['dateKey'] ?? '';
          return _fadePage(
            state: state,
            child: ChooseCardScreen(dateKey: dateKey),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.day,
        pageBuilder: (context, state) {
          final dateKey = state.pathParameters['dateKey'] ?? '';
          return _fadePage(
            state: state,
            child: DayDetailScreen(dateKey: dateKey),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.verify,
        pageBuilder: (context, state) {
          final id = state.pathParameters['verificationId'] ?? '';
          return _fadePage(
            state: state,
            child: VerificationScreen(verificationId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.privacy,
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const LegalScreen(
            title: 'Privacy',
            body:
                'StryK stores your name, phone, selected gym, and streak locally on this device. Demo mode does not send data to a server.',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.terms,
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const LegalScreen(
            title: 'Terms',
            body:
                'StryK is a consistency companion. Showing up at your gym for 20 continuous minutes inside the 40m zone secures the day. This demo runs entirely on-device.',
          ),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: (context, state) =>
                    _fadePage(state: state, child: const HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.streak,
                pageBuilder: (context, state) =>
                    _fadePage(state: state, child: const StreakScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                pageBuilder: (context, state) =>
                    _fadePage(state: state, child: const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
