import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_controller.dart';
import '../../widgets/stryk_logo.dart';
import '../routing/app_routes.dart';
import '../theme/app_theme.dart';

class StrykDrawer extends ConsumerWidget {
  const StrykDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: AppColors.backgroundElevated,
      width: (MediaQuery.sizeOf(context).width * 0.82).clamp(240.0, 330.0),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StrykLogo(height: 28, light: true),
              const SizedBox(height: 8),
              Text('StryK', style: AppTypography.label),
              const SizedBox(height: AppSpacing.xl),
              _item(context, 'Home', AppRoutes.home, replace: true),
              _item(context, 'My StryK', AppRoutes.streak, replace: true),
              _item(context, 'Change Gym', AppRoutes.selectGym, push: true),
              _item(context, 'Profile', AppRoutes.profile, replace: true),
              _item(context, 'Privacy & Terms', AppRoutes.privacy, push: true),
              _item(
                context,
                'Admin Panel',
                ref.watch(appControllerProvider).adminAuthenticated
                    ? AppRoutes.admin
                    : AppRoutes.adminLogin,
                push: true,
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await ref.read(appControllerProvider.notifier).logout();
                  if (context.mounted) context.go(AppRoutes.welcome);
                },
                child: Text(
                  'Logout',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    String label,
    String route, {
    bool push = false,
    bool replace = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 14,
      title: Text(label, style: AppTypography.bodyMedium),
      onTap: () {
        Navigator.pop(context);
        if (push) {
          context.push(route);
        } else if (replace) {
          context.go(route);
        } else {
          context.push(route);
        }
      },
    );
  }
}
