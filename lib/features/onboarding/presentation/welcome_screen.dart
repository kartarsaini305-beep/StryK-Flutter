import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_copy.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/stryk_button.dart';
import '../../../widgets/stryk_logo.dart';

/// Lightweight entry if onboarding already seen — routes usually skip here.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const StrykLogo(height: 30, light: true),
                const Spacer(),
                Text(AppCopy.welcomeHeadline, style: AppTypography.heading),
                const SizedBox(height: 12),
                Text(AppCopy.welcomeBody, style: AppTypography.body),
                const Spacer(),
                StrykButton(
                  label: AppCopy.getStarted,
                  onPressed: () => context.go(AppRoutes.onboarding),
                ),
                const SizedBox(height: 10),
                StrykButton(
                  label: AppCopy.logIn,
                  variant: StrykButtonVariant.secondary,
                  onPressed: () => context.go(AppRoutes.phone),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
