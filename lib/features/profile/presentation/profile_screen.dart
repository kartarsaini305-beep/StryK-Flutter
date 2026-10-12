import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/demo_chrome.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/stryk_button.dart';
import '../../../widgets/stryk_card.dart';
import '../../../widgets/stryk_logo.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final user = app.user;
    final gym = app.effectiveGym;
    final initials = (user?.name.isNotEmpty == true)
        ? user!.name
            .trim()
            .split(' ')
            .map((p) => p[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'SK';

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
          ),
          children: [
            Row(
              children: [
                Text('Profile', style: AppTypography.heading),
                const Spacer(),
                const StrykLogo(height: 22, light: true),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.55),
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(color: AppColors.amberGlow, blurRadius: 20),
                  ],
                ),
                child: Builder(
                  builder: (context) {
                    final path = user?.photoPath;
                    final hasPhoto =
                        path != null && path.isNotEmpty && File(path).existsSync();
                    return CircleAvatar(
                      radius: 42,
                      backgroundColor: AppColors.charcoal,
                      backgroundImage:
                          hasPhoto ? FileImage(File(path)) : null,
                      child: hasPhoto
                          ? null
                          : Text(
                              initials,
                              style: AppTypography.heading.copyWith(
                                color: AppColors.amber,
                                fontSize: 22,
                              ),
                            ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              user?.name ?? 'Athlete',
              style: AppTypography.heading.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              user?.phone ?? '',
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            if (gym != null) ...[
              const SizedBox(height: 2),
              Text(
                gym.name,
                style: AppTypography.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            StrykButton(
              label: 'Edit Profile',
              onPressed: () => context.push(AppRoutes.editProfile),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                StatCard(label: 'Current', value: '${app.streak.current}'),
                const SizedBox(width: 10),
                StatCard(label: 'Best', value: '${app.streak.best}'),
                const SizedBox(width: 10),
                StatCard(
                  label: 'Gym days',
                  value: '${app.streak.totalGymDays}',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('COMPETE', style: AppTypography.label),
            const SizedBox(height: AppSpacing.sm),
            StrykCard(
              padding: EdgeInsets.zero,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    _NavRow(
                      title: 'Leaderboard',
                      onTap: () => context.push(AppRoutes.leaderboard),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    _NavRow(
                      title: 'Monthly result',
                      onTap: () => context.push(AppRoutes.monthlyResult),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('SETTINGS', style: AppTypography.label),
            const SizedBox(height: AppSpacing.sm),
            StrykCard(
              padding: EdgeInsets.zero,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                      title: Text(
                        'Arrival nudges',
                        style: AppTypography.bodyMedium,
                      ),
                      value: app.settings.arrivalNudges,
                      activeThumbColor: AppColors.textOnLight,
                      activeTrackColor: AppColors.amber,
                      onChanged: (value) => ref
                          .read(appControllerProvider.notifier)
                          .setArrivalNudges(value),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                      title: Text(
                        'Rest day protection',
                        style: AppTypography.bodyMedium,
                      ),
                      value: app.settings.restDayProtection,
                      activeThumbColor: AppColors.textOnLight,
                      activeTrackColor: AppColors.amber,
                      onChanged: (value) => ref
                          .read(appControllerProvider.notifier)
                          .setRestDayProtection(value),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    _NavRow(
                      title: 'Change gym',
                      onTap: () => context.push(AppRoutes.selectGym),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    _NavRow(
                      title: 'Change phone',
                      onTap: () => context.push(AppRoutes.changePhone),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    _NavRow(
                      title: 'Privacy',
                      onTap: () => context.push(AppRoutes.privacy),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    _NavRow(
                      title: 'Terms',
                      onTap: () => context.push(AppRoutes.terms),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    _NavRow(
                      title: 'Admin Login',
                      muted: true,
                      onTap: () => context.push(AppRoutes.adminLogin),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14),
                      title: Text(
                        'Logout',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.error),
                      ),
                      onTap: () async {
                        await ref.read(appControllerProvider.notifier).logout();
                        if (context.mounted) context.go(AppRoutes.welcome);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.title,
    required this.onTap,
    this.muted = false,
  });

  final String title;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          color: muted ? AppColors.textMuted : AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
    );
  }
}
