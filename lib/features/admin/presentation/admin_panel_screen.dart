import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/stryk_button.dart';
import '../../../widgets/stryk_card.dart';
import '../../../widgets/stryk_logo.dart';
import '../models/admin_config.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    if (!app.adminAuthenticated) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: StrykButton(
            label: 'Admin Login',
            onPressed: () => context.go(AppRoutes.adminLogin),
          ),
        ),
      );
    }
    final config = app.adminConfig;
    final history = app.records.values.where((r) => r.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(appControllerProvider.notifier).logoutAdmin();
              if (context.mounted) {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.adminLogin);
                }
              }
            },
            child: Text(
              'Logout',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.md,
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
          ),
          children: [
            const StrykLogo(height: 24, light: true),
            const SizedBox(height: AppSpacing.md),
            Text('Runtime controls', style: AppTypography.heading.copyWith(fontSize: 24)),
            Text(
              'Changes apply to the live session engine without rebuilding the app.',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            _section(
              'Gym Settings',
              [
                _slider(
                  label: 'Minimum stay: ${config.minStayMinutes} min',
                  value: config.minStayMinutes.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  onChanged: (value) => _save(
                    ref,
                    config.copyWith(minStayMinutes: value.round()),
                  ),
                ),
                _slider(
                  label: 'Geofence radius: ${config.geofenceRadiusMeters.round()} m',
                  value: config.geofenceRadiusMeters,
                  min: 20,
                  max: 100,
                  divisions: 16,
                  onChanged: (value) => _save(
                    ref,
                    config.copyWith(geofenceRadiusMeters: value),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Gym detection', style: AppTypography.bodyMedium),
                  value: config.gymDetectionEnabled,
                  activeTrackColor: AppColors.amber,
                  onChanged: (value) => _save(
                    ref,
                    config.copyWith(gymDetectionEnabled: value),
                  ),
                ),
              ],
            ),
            _section(
              'Streak',
              [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Streak enabled', style: AppTypography.bodyMedium),
                  value: config.streakEnabled,
                  activeTrackColor: AppColors.amber,
                  onChanged: (value) =>
                      _save(ref, config.copyWith(streakEnabled: value)),
                ),
              ],
            ),
            _section(
              'Share Cards',
              [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Minimal'),
                  value: config.cardMinimalEnabled,
                  activeTrackColor: AppColors.amber,
                  onChanged: (value) =>
                      _save(ref, config.copyWith(cardMinimalEnabled: value)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Photo'),
                  value: config.cardPhotoEnabled,
                  activeTrackColor: AppColors.amber,
                  onChanged: (value) =>
                      _save(ref, config.copyWith(cardPhotoEnabled: value)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Achievement'),
                  value: config.cardAchievementEnabled,
                  activeTrackColor: AppColors.amber,
                  onChanged: (value) =>
                      _save(ref, config.copyWith(cardAchievementEnabled: value)),
                ),
              ],
            ),
            _section(
              'Demo Time Mode',
              [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'DEMO ONLY — 1 real second = 1 simulated minute. Never use in production.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Demo Mode ON/OFF', style: AppTypography.bodyMedium),
                  subtitle: Text(
                    config.demoTimeMode
                        ? 'Demo Time Mode is ON'
                        : 'Demo Time Mode is OFF',
                    style: AppTypography.label.copyWith(
                      color: config.demoTimeMode
                          ? AppColors.error
                          : AppColors.textMuted,
                    ),
                  ),
                  value: config.demoTimeMode,
                  activeTrackColor: AppColors.error,
                  onChanged: (value) =>
                      _save(ref, config.copyWith(demoTimeMode: value)),
                ),
              ],
            ),
            _section(
              'App',
              [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Maintenance mode', style: AppTypography.bodyMedium),
                  value: config.maintenanceMode,
                  activeTrackColor: AppColors.error,
                  onChanged: (value) =>
                      _save(ref, config.copyWith(maintenanceMode: value)),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Announcement', style: AppTypography.bodyMedium),
                  subtitle: Text(
                    config.announcement.isEmpty
                        ? 'No announcement'
                        : config.announcement,
                    style: AppTypography.label,
                  ),
                  trailing: const Icon(Icons.edit, color: AppColors.textMuted),
                  onTap: () async {
                    final controller =
                        TextEditingController(text: config.announcement);
                    final value = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: Text('Announcement', style: AppTypography.subheading),
                        content: TextField(
                          controller: controller,
                          maxLines: 3,
                          style: AppTypography.bodyMedium,
                          autofocus: true,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, controller.text.trim()),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    );
                    if (value != null) {
                      await _save(ref, config.copyWith(announcement: value));
                    }
                  },
                ),
              ],
            ),
            _section(
              'Users & Activity',
              [
                _stat('Signed-in user', app.user?.name ?? '—'),
                _stat('Phone', app.user?.phone ?? '—'),
                _stat('Active gym', app.gym?.name ?? 'None'),
                _stat('Completed gym days', '$history'),
                _stat('Current streak', '${app.streak.current}'),
                _stat(
                  'Today session',
                  app.session?.status.name ?? 'idle',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: StrykCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.subheading),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppColors.amber,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.label)),
          Flexible(
            child: Text(
              value,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(WidgetRef ref, AdminConfig config) {
    return ref.read(appControllerProvider.notifier).updateAdminConfig(config);
  }
}
