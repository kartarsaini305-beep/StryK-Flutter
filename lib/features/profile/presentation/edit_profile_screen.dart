import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/stryk_text_field.dart';
import '../../../features/media/presentation/image_adjust_screen.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/stryk_button.dart';
import '../../../widgets/stryk_card.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: ref.read(appControllerProvider).user?.name ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _name.text.trim();
    if (value.isEmpty) return;
    setState(() => _saving = true);
    await ref.read(appControllerProvider.notifier).saveProfile(name: value);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.charcoal,
        content: Text('Profile saved', style: AppTypography.bodyMedium),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      imageQuality: 92,
    );
    if (picked == null || !mounted) return;
    final cropped = await ImageAdjustScreen.open(
      context,
      sourcePath: picked.path,
      aspectRatio: 1,
      shape: ImageAdjustShape.circle,
      title: 'Profile photo',
    );
    if (cropped == null) return;
    await ref.read(appControllerProvider.notifier).saveProfile(photoPath: cropped);
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final user = app.user;
    final gym = app.effectiveGym;
    final photo = user?.photoPath;
    final phone = user?.phone ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
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
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: Stack(
                          children: [
                            Builder(
                              builder: (context) {
                                final hasPhoto = photo != null &&
                                    photo.isNotEmpty &&
                                    File(photo).existsSync();
                                return CircleAvatar(
                                  radius: 48,
                                  backgroundColor: AppColors.charcoal,
                                  backgroundImage: hasPhoto
                                      ? FileImage(File(photo))
                                      : null,
                                  child: hasPhoto
                                      ? null
                                      : const Icon(
                                          Icons.person,
                                          size: 40,
                                          color: AppColors.textMuted,
                                        ),
                                );
                              },
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.amber,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: AppColors.textOnLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    StrykTextField(
                      controller: _name,
                      label: 'Name',
                      hint: 'Your name',
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    StrykCard(
                      child: Column(
                        children: [
                          _linkRow(
                            label: 'Mobile number',
                            value: phone,
                            action: 'Change',
                            onTap: () => context.push(AppRoutes.changePhone),
                          ),
                          const Divider(height: 1, color: AppColors.borderSubtle),
                          _linkRow(
                            label: 'Gym',
                            value: gym?.name ?? 'Not selected',
                            action: 'Change Gym',
                            onTap: () => context.push(AppRoutes.selectGym),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    StrykButton(
                      label: 'Save changes',
                      loading: _saving,
                      onPressed: _save,
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

  Widget _linkRow({
    required String label,
    required String value,
    required String action,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: AppTypography.label),
      subtitle: Text(
        value,
        style: AppTypography.bodyMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: TextButton(
        onPressed: onTap,
        child: Text(
          action,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.amber),
        ),
      ),
    );
  }
}
