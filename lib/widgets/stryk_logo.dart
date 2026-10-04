import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../core/constants/app_copy.dart';

/// Official StryK wordmark. Transparent PNG — no white box.
/// Use [light] on dark surfaces so charcoal letters render as white.
class StrykLogo extends StatelessWidget {
  const StrykLogo({
    super.key,
    this.height = 44,
    this.semanticLabel = AppCopy.logoSemanticLabel,
    this.light = false,
    @Deprecated('White plate removed — use light:true on dark backgrounds')
    this.plate = false,
  });

  final double height;
  final String semanticLabel;
  final bool light;
  final bool plate;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: Image.asset(
        light || plate ? AppAssets.logoLight : AppAssets.logo,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      ),
    );
  }
}
