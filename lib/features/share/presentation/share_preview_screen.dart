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
import '../../../features/share/services/share_card_exporter.dart';
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

  ShareCardStyle get _style => ShareCardStyleX.parse(widget.styleName);

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
      _toast('Saved: ${saved.path}');
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
    final payload = SharePayload.fromRecord(record);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Card Preview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
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
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                child: Column(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 380,
                        maxHeight: constraints.maxHeight * 0.58,
                      ),
                      child: AspectRatio(
                        aspectRatio: 4 / 5,
                        child: RepaintBoundary(
                          key: _boundary,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: ShareCardCanvas(
                              payload: payload,
                              style: _style,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    StrykButton(
                      label: 'Share',
                      loading: _busy,
                      onPressed: _share,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    StrykButton(
                      label: 'Save',
                      variant: StrykButtonVariant.secondary,
                      onPressed: _save,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: StrykButton(
                            label: 'Change Style',
                            variant: StrykButtonVariant.secondary,
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StrykButton(
                            label: payload.photoPath == null
                                ? 'Add Photo'
                                : 'Photo',
                            variant: StrykButtonVariant.secondary,
                            onPressed: () => _pickPhoto(context),
                          ),
                        ),
                      ],
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
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _pickAndCrop(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _pickAndCrop(ImageSource.camera);
              },
            ),
            if (ref.read(appControllerProvider).records[widget.dateKey]
                    ?.optionalPhotoPath !=
                null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                title: const Text('Remove photo'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _removePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndCrop(ImageSource source) async {
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
  }
}
