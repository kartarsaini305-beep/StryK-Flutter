import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/demo_chrome.dart';
import '../../../core/widgets/share_card.dart';
import '../../../features/media/presentation/image_adjust_screen.dart';
import '../../../features/share/models/share_payload.dart';
import '../../../features/share/services/monthly_leaderboard_service.dart';
import '../../../features/sponsors/models/sponsor.dart';
import '../../../features/sponsors/services/sponsor_repository.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/pressable_scale.dart';
import '../../../widgets/stryk_button.dart';
import '../../../widgets/stryk_logo.dart';

class ChooseCardScreen extends ConsumerStatefulWidget {
  const ChooseCardScreen({super.key, required this.dateKey});

  final String dateKey;

  @override
  ConsumerState<ChooseCardScreen> createState() => _ChooseCardScreenState();
}

class _ChooseCardScreenState extends ConsumerState<ChooseCardScreen> {
  ShareCardStyle? _selected;
  int? _gymRank;
  List<ShareSponsor> _sponsors = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final app = ref.read(appControllerProvider);
    final user = app.user;
    final gym = app.effectiveGym?.name ?? '';
    final sponsors = await SponsorRepository().fetchActive(
      limit: 3,
      placement: SponsorPlacement.dailyCard,
    );
    final mapped = [
      for (final s in sponsors)
        ShareSponsor(name: s.name, logoUrl: s.logoUrl),
    ];
    int? rank;
    if (user != null && gym.isNotEmpty) {
      final month = MonthlyLeaderboardService.monthKey();
      final days = MonthlyLeaderboardService.verifiedDaysForMonth(
        app.records,
        month,
      );
      rank = await MonthlyLeaderboardService().gymRankForUser(
        userId: user.id.isEmpty ? 'local-user' : user.id,
        gymName: gym,
        month: month,
        localVerifiedDays: days,
        displayName: user.name,
      );
    }
    if (!mounted) return;
    setState(() {
      _gymRank = rank;
      _sponsors = mapped;
    });
  }

  Future<void> _addSessionPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose Image', style: AppTypography.subheading),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.amber),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined,
                    color: AppColors.amber),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2400,
      imageQuality: 92,
    );
    if (picked == null || !mounted) return;
    final cropped = await ImageAdjustScreen.open(
      context,
      sourcePath: picked.path,
      aspectRatio: 4 / 5,
      title: 'Session photo',
    );
    if (cropped == null) return;
    await ref
        .read(appControllerProvider.notifier)
        .saveRecordPhoto(widget.dateKey, cropped);
  }

  Future<void> _removeSessionPhoto() async {
    await ref
        .read(appControllerProvider.notifier)
        .saveRecordPhoto(widget.dateKey, null);
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final record = app.records[widget.dateKey];
    if (record == null || !record.isCompleted) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          title: 'Nothing to share yet',
          message: 'Complete a valid StryK first.',
        ),
      );
    }
    final month = MonthlyLeaderboardService.monthKey();
    final monthDays = MonthlyLeaderboardService.verifiedDaysForMonth(
      app.records,
      month,
    );
    final payload = SharePayload.fromRecord(
      record,
      gymRank: _gymRank,
      sponsors: _sponsors,
      displayName: app.user?.name ?? '',
      profilePhotoPath: app.user?.photoPath,
      currentStreak: app.streak.current,
      bestStreak: app.streak.best,
      verifiedDaysMonth: monthDays,
    );
    final hasPhoto = payload.photoPath != null;
    final styles = ShareCardStyle.values.where((style) {
      return switch (style) {
        ShareCardStyle.minimal => app.adminConfig.cardMinimalEnabled,
        ShareCardStyle.photo => app.adminConfig.cardPhotoEnabled,
        ShareCardStyle.achievement => app.adminConfig.cardAchievementEnabled,
      };
    }).toList();
    final previewMaxH = (MediaQuery.sizeOf(context).width - 48) * 5 / 4;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose your card'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.md,
                  AppSpacing.screenHorizontal,
                  AppSpacing.md,
                ),
                children: [
                  const Center(child: StrykLogo(height: 28, light: true)),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Share your streak',
                    style: AppTypography.heading,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _gymRank == null
                        ? 'Day ${payload.dayNumber} · pick a card'
                        : 'Day ${payload.dayNumber} · Gym rank #$_gymRank',
                    style: AppTypography.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: StrykButton(
                          label: hasPhoto ? 'Replace photo' : 'Add session photo',
                          variant: StrykButtonVariant.secondary,
                          onPressed: _addSessionPhoto,
                        ),
                      ),
                      if (hasPhoto) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: StrykButton(
                            label: 'Remove',
                            variant: StrykButtonVariant.secondary,
                            onPressed: _removeSessionPhoto,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final style in styles) ...[
                    PressableScale(
                      scale: 0.985,
                      onPressed: () => setState(() => _selected = style),
                      child: AnimatedScale(
                        scale: _selected == style ? 1.0 : 0.985,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: _selected == style
                                  ? AppColors.amber
                                  : AppColors.borderSubtle,
                              width: _selected == style ? 2 : 1,
                            ),
                            boxShadow: _selected == style
                                ? const [
                                    BoxShadow(
                                      color: AppColors.amberGlow,
                                      blurRadius: 22,
                                      offset: Offset(0, 8),
                                    ),
                                  ]
                                : null,
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                style.label.toUpperCase(),
                                style: AppTypography.label.copyWith(
                                  color: _selected == style
                                      ? AppColors.amber
                                      : AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(style.caption, style: AppTypography.body),
                              const SizedBox(height: 10),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: previewMaxH),
                                child: ShareCardCanvas(
                                  payload: payload,
                                  style: style,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                8,
                AppSpacing.screenHorizontal,
                AppSpacing.md,
              ),
              child: StrykButton(
                label: 'Continue',
                enabled: _selected != null,
                onPressed: _selected == null
                    ? null
                    : () => context.push(
                          AppRoutes.sharePreviewFor(
                            widget.dateKey,
                            _selected!.name,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
