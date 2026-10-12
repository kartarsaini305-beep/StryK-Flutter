import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/stryk_button.dart';
import '../../../widgets/stryk_logo.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  var _index = 0;

  static const _pages = [
    _PageData(
      title: 'Show up. Get verified.',
      body: 'StryK detects your gym and verifies real presence — not just a check-in selfie.',
      bullets: [
        (Icons.my_location_rounded, 'Auto gym detection'),
        (Icons.verified_rounded, 'Verified gym sessions'),
        (Icons.timelapse_rounded, 'Minimum-stay tracking'),
      ],
    ),
    _PageData(
      title: 'Turn sessions into cards.',
      body: 'Every completed StryK becomes a share-worthy story card with your streak and score.',
      bullets: [
        (Icons.style_rounded, '3 premium card templates'),
        (Icons.qr_code_2_rounded, 'Verifiable QR proof'),
        (Icons.photo_camera_rounded, 'Same session photo'),
      ],
    ),
    _PageData(
      title: 'Compete. Stay consistent.',
      body: 'Monthly leaderboards reset. Lifetime streak never does. Sponsors reward consistency.',
      bullets: [
        (Icons.emoji_events_rounded, 'Monthly championships'),
        (Icons.local_fire_department_rounded, 'Lifetime streak'),
        (Icons.card_giftcard_rounded, 'Sponsor challenges'),
      ],
    ),
  ];

  Future<void> _finish() async {
    await ref.read(appControllerProvider.notifier).markOnboardingSeen();
    if (!mounted) return;
    context.go(AppRoutes.phone);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _pages.length - 1;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  const StrykLogo(height: 28, light: true),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Skip',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(),
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.charcoal,
                                  AppColors.amber.withValues(alpha: 0.12),
                                  AppColors.background,
                                ],
                              ),
                              border: Border.all(color: AppColors.borderStrong),
                            ),
                            child: const Center(
                              child: StrykLogo(height: 56, light: true),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            p.title,
                            style: AppTypography.heading.copyWith(fontSize: 26),
                          ),
                          const SizedBox(height: 10),
                          Text(p.body, style: AppTypography.body.copyWith(height: 1.5)),
                          const SizedBox(height: 22),
                          for (final b in p.bullets) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Icon(b.$1, color: AppColors.amber, size: 18),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      b.$2,
                                      style: AppTypography.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(flex: 2),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final on = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: on ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: on ? AppColors.amber : AppColors.charcoalDeep,
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: StrykButton(
                label: last ? 'Get Started' : 'Continue',
                onPressed: () {
                  if (last) {
                    _finish();
                  } else {
                    _page.nextPage(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageData {
  const _PageData({
    required this.title,
    required this.body,
    required this.bullets,
  });
  final String title;
  final String body;
  final List<(IconData, String)> bullets;
}
