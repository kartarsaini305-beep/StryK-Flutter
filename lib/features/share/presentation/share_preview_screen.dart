import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/demo_chrome.dart';
import '../../../core/widgets/share_card.dart';
import '../../../features/media/presentation/image_adjust_screen.dart';
import '../../../features/share/models/share_payload.dart';
import '../../../features/share/services/monthly_leaderboard_service.dart';
import '../../../features/share/services/share_card_exporter.dart';
import '../../../features/sponsors/models/sponsor.dart';
import '../../../features/sponsors/services/sponsor_repository.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/stryk_button.dart';

class SharePreviewScreen extends ConsumerStatefulWidget {
  const SharePreviewScreen({
    super.key,
    required this.dateKey,
    required this.styleName,
  });

  final String dateKey;
  final String styleName;

  @override
  ConsumerState<SharePreviewScreen> createState() => _SharePreviewScreenState();
}

class _SharePreviewScreenState extends ConsumerState<SharePreviewScreen> {
  final _boundary = GlobalKey();
  final _exporter = const ShareCardExporter();
  var _busy = false;
  int? _gymRank;
  List<ShareSponsor> _sponsors = const [];

  ShareCardStyle get _style => ShareCardStyleX.parse(widget.styleName);

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

  SharePayload _payload() {
    final app = ref.read(appControllerProvider);
    final record = app.records[widget.dateKey]!;
    final month = MonthlyLeaderboardService.monthKey();
    final monthDays = MonthlyLeaderboardService.verifiedDaysForMonth(
      app.records,
      month,
    );
    return SharePayload.fromRecord(
      record,
      gymRank: _gymRank,
      sponsors: _sponsors,
      displayName: app.user?.name ?? '',
      profilePhotoPath: app.user?.photoPath,
      currentStreak: app.streak.current,
      bestStreak: app.streak.best,
      verifiedDaysMonth: monthDays,
    );
  }

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      final file = await _exporter.capturePng(_boundary);
      await _exporter.shareFile(file);
    } catch (_) {
      _toast('Could not export the card.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      final file = await _exporter.capturePng(_boundary);
      final dir = await getApplicationDocumentsDirectory();
      final saved = await file.copy(
        '${dir.path}/stryk-${widget.dateKey}-${_style.name}.png',
      );
      // Also surface via share sheet so user can Save Image / Files.
      await _exporter.shareFile(
        saved,
        text: 'StryK progress card — save to gallery from the share sheet.',
      );
      _toast('Card ready — use the share sheet to save to Photos.');
    } catch (_) {
      _toast('Could not save the card.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removePhoto() async {
    await ref
        .read(appControllerProvider.notifier)
        .saveRecordPhoto(widget.dateKey, null);
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.charcoal,
        content: Text(message, style: AppTypography.bodyMedium),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final record = ref.watch(appControllerProvider).records[widget.dateKey];
    if (record == null || !record.isCompleted) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          title: 'Nothing to share yet',
          message: 'Open a completed day from history.',
        ),
      );
    }
    final payload = _payload();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Share Progress'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.md,
                AppSpacing.screenHorizontal,
                AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 380,
                        maxHeight:
                            (constraints.maxHeight * 0.58).clamp(220.0, 460.0),
                      ),
                      child: AspectRatio(
                        aspectRatio: 4 / 5,
                        child: RepaintBoundary(
                          key: _boundary,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            child: ShareCardCanvas(
                              key: ValueKey(
                                '${payload.photoPath}-${payload.gymRank}-${payload.profilePhotoPath}',
                              ),
                              payload: payload,
                              style: _style,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pickPhoto(context),
                      icon: Icon(
                        payload.photoPath == null
                            ? Icons.add_photo_alternate_outlined
                            : Icons.photo_outlined,
                        color: AppColors.amber,
                      ),
                      label: Text(
                        payload.photoPath == null
                            ? 'Add Photo'
                            : 'Change Photo',
                        style: AppTypography.bodyMedium,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.white,
                        side: const BorderSide(color: AppColors.borderStrong),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    StrykButton(
                      label: 'Share',
                      loading: _busy,
                      onPressed: _share,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    StrykButton(
                      label: 'Save to Gallery',
                      variant: StrykButtonVariant.secondary,
                      onPressed: _busy ? null : _save,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () {
                        if (context.canPop()) context.pop();
                      },
                      child: Text(
                        'Change style',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickPhoto(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('Choose Image', style: AppTypography.subheading),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _PickerTab(
                        label: 'Gallery',
                        icon: Icons.photo_library_outlined,
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          await _pickAndCrop(ImageSource.gallery);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PickerTab(
                        label: 'Camera',
                        icon: Icons.photo_camera_outlined,
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          await _pickAndCrop(ImageSource.camera);
                        },
                      ),
                    ),
                  ],
                ),
                if (ref
                        .read(appControllerProvider)
                        .records[widget.dateKey]
                        ?.optionalPhotoPath !=
                    null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await _removePhoto();
                    },
                    child: Text(
                      'Remove photo',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndCrop(ImageSource source) async {
    try {
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
        title: 'Fit photo to card',
      );
      if (cropped == null) return;
      await ref
          .read(appControllerProvider.notifier)
          .saveRecordPhoto(widget.dateKey, cropped);
    } catch (_) {
      _toast('Could not open camera or gallery. Check permissions.');
    }
  }
}

class _PickerTab extends StatelessWidget {
  const _PickerTab({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.charcoal,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, color: AppColors.amber),
              const SizedBox(height: 8),
              Text(label, style: AppTypography.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
