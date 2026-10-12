import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Renders a sponsor logo from http(s) URL or local absolute file path.
class SponsorLogo extends StatelessWidget {
  const SponsorLogo({
    super.key,
    required this.urlOrPath,
    this.fit = BoxFit.contain,
    this.fallbackIconSize = 18,
  });

  final String urlOrPath;
  final BoxFit fit;
  final double fallbackIconSize;

  @override
  Widget build(BuildContext context) {
    final path = urlOrPath.trim();
    if (path.isEmpty) {
      return Icon(
        Icons.handshake_outlined,
        color: AppColors.amber,
        size: fallbackIconSize,
      );
    }
    final isNetwork =
        path.startsWith('http://') || path.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (_, _, _) => Icon(
          Icons.handshake_outlined,
          color: AppColors.amber,
          size: fallbackIconSize,
        ),
      );
    }
    final file = File(path);
    if (!file.existsSync()) {
      return Icon(
        Icons.handshake_outlined,
        color: AppColors.amber,
        size: fallbackIconSize,
      );
    }
    return Image.file(
      file,
      fit: fit,
      errorBuilder: (_, _, _) => Icon(
        Icons.handshake_outlined,
        color: AppColors.amber,
        size: fallbackIconSize,
      ),
    );
  }
}
