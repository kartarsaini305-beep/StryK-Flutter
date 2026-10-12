import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/stryk_text_field.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/stryk_button.dart';
import '../../../widgets/stryk_card.dart';
import '../../../widgets/stryk_logo.dart';
import '../../sponsors/models/sponsor.dart';
import '../../sponsors/presentation/admin_sponsors_section.dart';
import '../../share/models/monthly_result.dart';
import '../../share/services/monthly_leaderboard_service.dart';
import '../../share/services/monthly_result_repository.dart';
import '../../sponsors/services/sponsor_repository.dart';
import '../models/admin_config.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  late final TextEditingController _gymName;
  late final TextEditingController _lat;
  late final TextEditingController _lng;

  @override
  void initState() {
    super.initState();
    final config = ref.read(appControllerProvider).adminConfig;
    final gym = ref.read(appControllerProvider).effectiveGym;
    _gymName = TextEditingController(
      text: config.gymNameOverride.isEmpty
          ? (gym?.name ?? '')
          : config.gymNameOverride,
    );
    _lat = TextEditingController(
      text: (config.gymLatitude ?? gym?.location.latitude)?.toString() ?? '',
    );
    _lng = TextEditingController(
      text: (config.gymLongitude ?? gym?.location.longitude)?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _gymName.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  Future<void> _save(AdminConfig config) {
    return ref.read(appControllerProvider.notifier).updateAdminConfig(config);
  }

  Future<void> _saveGymFields(AdminConfig config) async {
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    await _save(
      config.copyWith(
        gymNameOverride: _gymName.text.trim(),
        gymLatitude: lat,
        gymLongitude: lng,
        clearGymCoords: lat == null || lng == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                const StrykLogo(height: 28, light: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Admin Control Panel',
                    style: AppTypography.heading.copyWith(fontSize: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Gym · Session · Sponsors · Campaigns. Live engine controls.',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            _section(
              'Gym Settings',
              [
                StrykTextField(controller: _gymName, label: 'Gym name'),
                const SizedBox(height: AppSpacing.sm),
                StrykTextField(
                  controller: _lat,
                  label: 'Latitude',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                StrykTextField(
                  controller: _lng,
                  label: 'Longitude',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                StrykButton(
                  label: 'Save gym details',
                  variant: StrykButtonVariant.secondary,
                  onPressed: () => _saveGymFields(config),
                ),
                const SizedBox(height: AppSpacing.md),
                _slider(
                  label: 'Check-in radius: ${config.checkInRadiusMeters.round()} m',
                  value: config.checkInRadiusMeters,
                  min: 20,
                  max: 200,
                  divisions: 36,
                  onChanged: (value) =>
                      _save(config.copyWith(checkInRadiusMeters: value)),
                ),
              ],
            ),
            _section(
              'Session',
              [
                _slider(
                  label: 'Minimum stay: ${config.minStayMinutes} min',
                  value: config.minStayMinutes.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  onChanged: (value) =>
                      _save(config.copyWith(minStayMinutes: value.round())),
                ),
                _slider(
                  label:
                      'Checkout radius: ${config.checkOutRadiusMeters.round()} m',
                  value: config.checkOutRadiusMeters,
                  min: 20,
                  max: 200,
                  divisions: 36,
                  onChanged: (value) =>
                      _save(config.copyWith(checkOutRadiusMeters: value)),
                ),
                _slider(
                  label:
                      'Outside duration: ${config.outsideDurationMinutes} min',
                  value: config.outsideDurationMinutes.toDouble(),
                  min: 1,
                  max: 15,
                  divisions: 14,
                  onChanged: (value) => _save(
                    config.copyWith(outsideDurationMinutes: value.round()),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Gym detection', style: AppTypography.bodyMedium),
                  value: config.gymDetectionEnabled,
                  activeTrackColor: AppColors.amber,
                  onChanged: (value) =>
                      _save(config.copyWith(gymDetectionEnabled: value)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Streak enabled', style: AppTypography.bodyMedium),
                  value: config.streakEnabled,
                  activeTrackColor: AppColors.amber,
                  onChanged: (value) =>
                      _save(config.copyWith(streakEnabled: value)),
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
                    'DEMO ONLY — 1 real second = 1 simulated minute.',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.error),
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
                      _save(config.copyWith(demoTimeMode: value)),
                ),
              ],
            ),
            _section(
              'Cards',
              [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Minimal'),
                  value: config.cardMinimalEnabled,
                  activeTrackColor: AppColors.amber,
                  onChanged: (value) =>
                      _save(config.copyWith(cardMinimalEnabled: value)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Photo'),
                  value: config.cardPhotoEnabled,
                  activeTrackColor: AppColors.amber,
                  onChanged: (value) =>
                      _save(config.copyWith(cardPhotoEnabled: value)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Achievement'),
                  value: config.cardAchievementEnabled,
                  activeTrackColor: AppColors.amber,
                  onChanged: (value) =>
                      _save(config.copyWith(cardAchievementEnabled: value)),
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
                      _save(config.copyWith(maintenanceMode: value)),
                ),
              ],
            ),
            _section(
              'Monthly Leaderboard → Sponsors',
              [
                Text(
                  '3 pools: App · Daily card · Monthly card. Pick placement when adding a sponsor.',
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.md),
                const AdminSponsorsSection(),
              ],
            ),
            _section(
              'Monthly Competition',
              [
                Text(
                  'Top 5 is calculated automatically from verified gym days. Configure sponsor branding, then publish to lock the month.',
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.md),
                StrykButton(
                  label: 'Publish monthly results',
                  variant: StrykButtonVariant.secondary,
                  onPressed: () => _publishMonth(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                StrykButton(
                  label: 'Save draft snapshot',
                  variant: StrykButtonVariant.ghost,
                  onPressed: () => _saveDraft(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                StrykButton(
                  label: 'Open leaderboard',
                  variant: StrykButtonVariant.ghost,
                  onPressed: () => context.push(AppRoutes.leaderboard),
                ),
                const SizedBox(height: AppSpacing.sm),
                StrykButton(
                  label: 'Preview monthly result',
                  variant: StrykButtonVariant.ghost,
                  onPressed: () => context.push(AppRoutes.monthlyResult),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<List<MonthlyPlace>> _liveTopFive() async {
    final app = ref.read(appControllerProvider);
    final month = MonthlyLeaderboardService.monthKey();
    final days = MonthlyLeaderboardService.verifiedDaysForMonth(
      app.records,
      month,
    );
    final user = app.user;
    final local = user == null
        ? null
        : MonthlyPlace(
            userId: user.id,
            displayName: user.name.trim().isEmpty ? 'Athlete' : user.name.trim(),
            verifiedDays: days,
            gymName: app.effectiveGym?.name ?? '',
          );
    if (local != null && days > 0) {
      await MonthlyLeaderboardService().syncUserEntry(
        userId: local.userId,
        displayName: local.displayName,
        verifiedDays: days,
        gymName: local.gymName,
      );
    }
    return MonthlyLeaderboardService().fetchTop(
      month: month,
      limit: 5,
      localFallback: local,
    );
  }

  Future<void> _saveDraft(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final month = MonthlyResultRepository.monthKey();
      final top = await _liveTopFive();
      final sponsors = await SponsorRepository().fetchActive(
        limit: 5,
        placement: SponsorPlacement.monthlyCard,
      );
      await MonthlyResultRepository().saveDraft(
        month: month,
        topFive: top,
        sponsors: sponsors,
      );
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.charcoal,
          content: Text('Draft saved for $month', style: AppTypography.bodyMedium),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.charcoal,
          content: Text('Draft could not be saved. $e', style: AppTypography.bodyMedium),
        ),
      );
    }
  }

  Future<void> _publishMonth(BuildContext context) async {
    final month = MonthlyResultRepository.monthKey();
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.charcoal,
        content: Text('Publishing $month…', style: AppTypography.bodyMedium),
      ),
    );
    try {
      final top = await _liveTopFive();
      if (top.isEmpty) {
        throw StateError('No verified sessions this month yet.');
      }
      final sponsors = await SponsorRepository().fetchActive(
        limit: 5,
        placement: SponsorPlacement.monthlyCard,
      );
      await MonthlyResultRepository().publishMonth(
        month: month,
        topFive: top,
        sponsors: sponsors,
      );
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.charcoal,
          content: Text(
            'Month $month published. Lifetime streak unchanged.',
            style: AppTypography.bodyMedium,
          ),
        ),
      );
      context.push(AppRoutes.monthlyResult);
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.charcoal,
          content: Text(
            'Monthly result could not be finalized. $e',
            style: AppTypography.bodyMedium,
          ),
        ),
      );
    }
  }

  Widget _section(String title, List<Widget> children) {
    final icon = switch (title) {
      'Gym Settings' || 'Gym' => Icons.fitness_center_rounded,
      'Session' => Icons.timer_outlined,
      'Streak' => Icons.local_fire_department_rounded,
      'Cards' => Icons.style_outlined,
      'App' => Icons.settings_outlined,
      'Sponsors' ||
      'Sponsors (Firestore)' ||
      'Monthly Leaderboard → Sponsors' =>
        Icons.handshake_outlined,
      'Monthly Competition' => Icons.emoji_events_outlined,
      _ => Icons.tune_rounded,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: StrykCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.amber, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: AppTypography.subheading),
                ),
              ],
            ),
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
}
