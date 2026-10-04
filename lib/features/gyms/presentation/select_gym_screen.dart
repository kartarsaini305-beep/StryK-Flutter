import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/geo.dart';
import '../../../core/widgets/demo_chrome.dart';
import '../../../core/widgets/gym_card.dart';
import '../../../core/widgets/gym_map.dart';
import '../../../core/widgets/stryk_text_field.dart';
import '../../../features/gyms/models/gym.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/stryk_button.dart';

class SelectGymScreen extends ConsumerStatefulWidget {
  const SelectGymScreen({super.key});

  @override
  ConsumerState<SelectGymScreen> createState() => _SelectGymScreenState();
}

class _SelectGymScreenState extends ConsumerState<SelectGymScreen> {
  final _search = TextEditingController();
  Gym? _highlighted;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openSheet(Gym gym) async {
    setState(() => _highlighted = gym);
    final app = ref.read(appControllerProvider);
    final distance = formatDistance(gym.location.distanceTo(app.location.point));
    var step = 0;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.sm,
                  AppSpacing.screenHorizontal,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(gym.name, style: AppTypography.heading.copyWith(fontSize: 24)),
                    const SizedBox(height: 6),
                    Text(gym.address, style: AppTypography.body),
                    const SizedBox(height: 6),
                    Text(distance, style: AppTypography.label.copyWith(color: AppColors.amber)),
                    const SizedBox(height: AppSpacing.lg),
                    if (step == 0)
                      StrykButton(
                        label: 'Select this gym',
                        onPressed: () => setModal(() => step = 1),
                      )
                    else ...[
                      Text(
                        'This will be your active gym.',
                        style: AppTypography.body,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      StrykButton(
                        label: 'Confirm gym',
                        onPressed: () async {
                          await ref.read(appControllerProvider.notifier).selectGym(gym);
                          HapticFeedback.mediumImpact();
                          if (context.mounted) Navigator.pop(context);
                          if (!mounted) return;
                          if (this.context.canPop()) {
                            this.context.pop();
                          } else {
                            this.context.go(AppRoutes.home);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gyms = ref.watch(gymServiceProvider).search(_search.text);
    final app = ref.watch(appControllerProvider);
    final canPop = app.hasGym;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && canPop && context.canPop()) {
          context.pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Choose your gym'),
        automaticallyImplyLeading: canPop,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.home);
                  }
                },
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.sm,
                AppSpacing.screenHorizontal,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DemoModeBadge(),
                  const SizedBox(height: AppSpacing.sm),
                  StrykTextField(
                    controller: _search,
                    hint: 'Search gyms',
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 220,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: GymMap(
                    gyms: gyms,
                    user: app.location.point,
                    selectedId: _highlighted?.id ?? app.gym?.id,
                    onSelect: _openSheet,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: gyms.isEmpty
                  ? const EmptyState(
                      title: 'No gyms found',
                      message: 'Try another search.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenHorizontal,
                        0,
                        AppSpacing.screenHorizontal,
                        AppSpacing.lg,
                      ),
                      itemCount: gyms.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final gym = gyms[index];
                        return GymCard(
                          gym: gym,
                          distanceLabel: formatDistance(
                            gym.location.distanceTo(app.location.point),
                          ),
                          selected: gym.id == (_highlighted?.id ?? app.gym?.id),
                          onTap: () => _openSheet(gym),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
