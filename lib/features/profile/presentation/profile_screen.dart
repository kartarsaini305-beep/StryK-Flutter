import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/demo_chrome.dart';
import '../../../core/widgets/gym_card.dart';
import '../../../features/media/presentation/image_adjust_screen.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/stryk_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final user = app.user;
    final gym = app.gym;
    final initials = (user?.name.isNotEmpty == true)
        ? user!.name.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase()
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
            Center(
              child: GestureDetector(
                onTap: () async {
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 2400,
                    imageQuality: 92,
                  );
                  if (picked == null || !context.mounted) return;
                  final cropped = await ImageAdjustScreen.open(
                    context,
                    sourcePath: picked.path,
                    aspectRatio: 1,
                    shape: ImageAdjustShape.circle,
                    title: 'Profile photo',
                  );
                  if (cropped == null) return;
                  await ref
                      .read(appControllerProvider.notifier)
                      .saveProfile(photoPath: cropped);
                },
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.charcoal,
                  backgroundImage: user?.photoPath != null && File(user!.photoPath!).existsSync()
                      ? FileImage(File(user.photoPath!))
                      : null,
                  child: user?.photoPath == null
                      ? Text(initials, style: AppTypography.heading.copyWith(color: AppColors.amber))
                      : null,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(user?.name ?? 'Athlete', style: AppTypography.heading, textAlign: TextAlign.center),
            Text(
              user?.city.isNotEmpty == true ? user!.city : 'Add your city',
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            if (user?.goal.isNotEmpty == true)
              Text(user!.goal, style: AppTypography.label, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                StatCard(label: 'Current', value: '${app.streak.current}'),
                const SizedBox(width: 10),
                StatCard(label: 'Best', value: '${app.streak.best}'),
                const SizedBox(width: 10),
                StatCard(label: 'Gym days', value: '${app.streak.totalGymDays}'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Active gym', style: AppTypography.label),
            const SizedBox(height: AppSpacing.sm),
            if (gym == null)
              const EmptyState(
                title: 'Choose your gym',
                message: 'Select one gym so StryK can detect when you show up.',
              )
            else
              GymCard(
                gym: gym,
                distanceLabel: 'Active',
                selected: true,
                onTap: () => context.push(AppRoutes.selectGym),
              ),
            const SizedBox(height: AppSpacing.lg),
            _row(context, 'Change gym', () => context.push(AppRoutes.selectGym)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Arrival nudges', style: AppTypography.bodyMedium),
              value: app.settings.arrivalNudges,
              activeThumbColor: AppColors.textOnLight,
              activeTrackColor: AppColors.amber,
              onChanged: (value) =>
                  ref.read(appControllerProvider.notifier).setArrivalNudges(value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Rest day protection', style: AppTypography.bodyMedium),
              subtitle: Text(
                'Sundays stay safe. One save every 10 days.',
                style: AppTypography.label,
              ),
              value: app.settings.restDayProtection,
              activeThumbColor: AppColors.textOnLight,
              activeTrackColor: AppColors.amber,
              onChanged: (value) =>
                  ref.read(appControllerProvider.notifier).setRestDayProtection(value),
            ),
            _row(context, 'Partner offers', () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.charcoal,
                  content: Text('Partner offers are coming later.', style: AppTypography.bodyMedium),
                ),
              );
            }),
            _row(context, 'Privacy', () => context.push(AppRoutes.privacy)),
            _row(context, 'Terms', () => context.push(AppRoutes.terms)),
            const SizedBox(height: AppSpacing.lg),
            StrykCard(
              child: Column(
                children: [
                  _row(
                    context,
                    'Delete account & data',
                    () => _confirm(
                      context,
                      title: 'Delete account & data',
                      body: 'This clears local demo data on this device.',
                      action: 'Delete',
                      onConfirm: () async {
                        await ref.read(appControllerProvider.notifier).deleteAccount();
                        if (context.mounted) context.go(AppRoutes.welcome);
                      },
                    ),
                    destructive: true,
                  ),
                  _row(
                    context,
                    'Logout',
                    () async {
                      await ref.read(appControllerProvider.notifier).logout();
                      if (context.mounted) context.go(AppRoutes.welcome);
                    },
                    destructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    VoidCallback onTap, {
    bool destructive = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 16,
      title: Text(
        label,
        style: AppTypography.bodyMedium.copyWith(
          color: destructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: onTap,
    );
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
    required Future<void> Function() onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(title, style: AppTypography.subheading),
          content: Text(body, style: AppTypography.body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await onConfirm();
              },
              child: Text(action, style: const TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }
}
