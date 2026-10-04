import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/demo_chrome.dart';
import '../../../core/widgets/share_card.dart';
import '../../../features/share/models/share_payload.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/pressable_scale.dart';
import '../../../widgets/stryk_logo.dart';

class ChooseCardScreen extends ConsumerStatefulWidget {
  const ChooseCardScreen({super.key, required this.dateKey});

  final String dateKey;

  @override
  ConsumerState<ChooseCardScreen> createState() => _ChooseCardScreenState();
}

class _ChooseCardScreenState extends ConsumerState<ChooseCardScreen> {
  ShareCardStyle? _selected;

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
    final payload = SharePayload.fromRecord(record);
    final styles = ShareCardStyle.values.where((style) {
      return switch (style) {
        ShareCardStyle.minimal => app.adminConfig.cardMinimalEnabled,
        ShareCardStyle.photo => app.adminConfig.cardPhotoEnabled,
        ShareCardStyle.achievement => app.adminConfig.cardAchievementEnabled,
      };
    }).toList();

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
                  const Center(child: StrykLogo(height: 22, light: true)),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'DAY ${payload.dayNumber}',
                    style: AppTypography.heading,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Same verified data. Three looks.',
                    style: AppTypography.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final style in styles) ...[
                    PressableScale(
                      onPressed: () => setState(() => _selected = style),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: _selected == style
                                ? AppColors.amber
                                : AppColors.borderSubtle,
                            width: _selected == style ? 2 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(style.label.toUpperCase(), style: AppTypography.label),
                            const SizedBox(height: 2),
                            Text(style.caption, style: AppTypography.body),
                            const SizedBox(height: 10),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 420),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                child: ShareCardCanvas(
                                  payload: payload,
                                  style: style,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                0,
                AppSpacing.screenHorizontal,
                AppSpacing.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.textOnLight,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: _selected == null
                      ? null
                      : () async {
                          await ref
                              .read(appControllerProvider.notifier)
                              .saveCardStyle(widget.dateKey, _selected!);
                          if (!context.mounted) return;
                          context.push(
                            AppRoutes.sharePreviewFor(
                              widget.dateKey,
                              _selected!.name,
                            ),
                          );
                        },
                  child: Text(
                    'Continue',
                    style: AppTypography.button,
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
