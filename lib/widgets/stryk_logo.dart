import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../core/constants/app_copy.dart';
import '../core/theme/app_theme.dart';

enum StrykLogoVariant {
  /// Gold S mark only.
  mark,

  /// S + STRYK wordmark (compact headers).
  wordmark,

  /// S + STRYK + tagline (hero / brand moments).
  full,
}

/// Official STRYK brand logo — mark / wordmark / full lockup.
class StrykLogo extends StatelessWidget {
  const StrykLogo({
    super.key,
    this.height = 28,
    this.semanticLabel = AppCopy.logoSemanticLabel,
    this.variant = StrykLogoVariant.wordmark,
    this.light = true,
    this.showTagline = false,
    @Deprecated('Use variant') this.showMark = false,
    @Deprecated('Unused') this.plate = false,
  });

  final double height;
  final String semanticLabel;
  final StrykLogoVariant variant;
  final bool light;
  final bool showTagline;
  final bool showMark;
  final bool plate;

  StrykLogoVariant get _resolved {
    if (showTagline) return StrykLogoVariant.full;
    return variant;
  }

  @override
  Widget build(BuildContext context) {
    final v = _resolved;
    return Semantics(
      label: semanticLabel,
      child: switch (v) {
        StrykLogoVariant.mark => _Mark(height: height),
        StrykLogoVariant.wordmark => _Wordmark(height: height),
        StrykLogoVariant.full => _Full(height: height),
      },
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.mark,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => Icon(
        Icons.bolt_rounded,
        color: AppColors.amber,
        size: height,
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    final markH = height;
    final textSize = (height * 0.72).clamp(11.0, 28.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Mark(height: markH),
        SizedBox(width: height * 0.28),
        Flexible(
          child: Text(
            'STRYK',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
              fontSize: textSize,
              letterSpacing: textSize * 0.08,
              color: AppColors.white,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _Full extends StatelessWidget {
  const _Full({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    final markH = height;
    final titleSize = (height * 0.62).clamp(12.0, 26.0);
    final tagSize = (height * 0.22).clamp(7.0, 11.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Mark(height: markH),
        SizedBox(width: height * 0.28),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STRYK',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                  fontSize: titleSize,
                  letterSpacing: titleSize * 0.08,
                  color: AppColors.white,
                  height: 1,
                ),
              ),
              SizedBox(height: height * 0.08),
              Text(
                AppCopy.brandLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: tagSize,
                  letterSpacing: 1.4,
                  color: AppColors.amber,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact gold S for headers / splash phase 1.
class StrykMark extends StatelessWidget {
  const StrykMark({super.key, this.size = 28, this.glow = true});

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final mark = StrykLogo(height: size.clamp(16, 96), variant: StrykLogoVariant.mark);
    if (!glow) return mark;
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.amber.withValues(alpha: 0.35),
            blurRadius: size * 0.45,
          ),
        ],
      ),
      child: mark,
    );
  }
}

/// Legacy alias.
class StrykEmberMark extends StatelessWidget {
  const StrykEmberMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) => StrykMark(size: size * 0.55);
}
