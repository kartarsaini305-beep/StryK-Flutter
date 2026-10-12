import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/stryk_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _markOpacity;
  late final Animation<double> _markScale;
  late final Animation<double> _fullOpacity;
  late final Animation<double> _glow;
  var _navigated = false;
  var _animationDone = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _markOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 30),
      TweenSequenceItem(tween: ConstantTween(1), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(0), weight: 25),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    _markScale = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.35, curve: Curves.easeOutBack),
      ),
    );
    _fullOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.85, curve: Curves.easeOutCubic),
    );
    _glow = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.9, curve: Curves.easeOut),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationDone = true;
        _goIfReady();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goIfReady() {
    if (_navigated || !mounted || !_animationDone) return;
    final dest = destinationFor(ref.read(appControllerProvider));
    if (dest == null) return;
    _navigated = true;
    Future<void>.delayed(AppDurations.splashHold, () {
      if (!mounted) return;
      context.go(dest);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appControllerProvider, (_, next) {
      if (next.ready) _goIfReady();
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.splashBackground,
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.12),
                      radius: 0.95,
                      colors: [
                        AppColors.amber.withValues(alpha: 0.16 * _glow.value),
                        AppColors.background,
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: _markOpacity.value.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: _markScale.value,
                          child: const StrykMark(size: 88, glow: true),
                        ),
                      ),
                      Opacity(
                        opacity: _fullOpacity.value,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: StrykLogo(
                            height: 48,
                            variant: StrykLogoVariant.full,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
