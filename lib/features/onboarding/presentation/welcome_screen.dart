import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_copy.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/demo_chrome.dart';
import '../../../widgets/stryk_button.dart';
import '../../../widgets/stryk_logo.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _interval(double begin, double end) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  Widget _enter({
    required Animation<double> animation,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.xl,
              AppSpacing.screenHorizontal,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _enter(
                  animation: _interval(0, 0.45),
                  child: Row(
                    children: [
                      const StrykLogo(height: 28, light: true),
                      const Spacer(),
                      const DemoModeBadge(),
                    ],
                  ),
                ),
                const Spacer(),
                _enter(
                  animation: _interval(0.12, 0.58),
                  child: Text(
                    AppCopy.welcomeHeadline,
                    style: AppTypography.heading,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _enter(
                  animation: _interval(0.22, 0.7),
                  child: Text(
                    AppCopy.welcomeBody,
                    style: AppTypography.body,
                  ),
                ),
                const Spacer(),
                _enter(
                  animation: _interval(0.4, 0.9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StrykButton(
                        label: AppCopy.getStarted,
                        onPressed: () => context.push(AppRoutes.phone),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      StrykButton(
                        label: AppCopy.logIn,
                        variant: StrykButtonVariant.secondary,
                        onPressed: () => context.push(AppRoutes.phone),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
