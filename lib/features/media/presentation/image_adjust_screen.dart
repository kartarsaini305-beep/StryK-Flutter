import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_theme.dart';

enum ImageAdjustShape { rect, circle }

/// Instagram-style zoom / pan / crop. Returns cropped file path on confirm.
class ImageAdjustScreen extends StatefulWidget {
  const ImageAdjustScreen({
    super.key,
    required this.sourcePath,
    this.aspectRatio = 1,
    this.shape = ImageAdjustShape.rect,
    this.title = 'Adjust photo',
  });

  final String sourcePath;
  final double aspectRatio;
  final ImageAdjustShape shape;
  final String title;

  static Future<String?> open(
    BuildContext context, {
    required String sourcePath,
    double aspectRatio = 1,
    ImageAdjustShape shape = ImageAdjustShape.rect,
    String title = 'Adjust photo',
  }) {
    return Navigator.of(context, rootNavigator: true).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ImageAdjustScreen(
          sourcePath: sourcePath,
          aspectRatio: aspectRatio,
          shape: shape,
          title: title,
        ),
      ),
    );
  }

  @override
  State<ImageAdjustScreen> createState() => _ImageAdjustScreenState();
}

class _ImageAdjustScreenState extends State<ImageAdjustScreen> {
  final _boundaryKey = GlobalKey();
  final _transform = TransformationController();
  var _busy = false;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/stryk-crop-${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(Uint8List.view(bytes.buffer));
      if (!mounted) return;
      Navigator.of(context).pop(file.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.charcoal,
          content: Text(
            'Could not crop this photo.',
            style: AppTypography.bodyMedium,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxW = size.width - 32;
    final maxH = size.height * 0.58;
    var cropW = maxW;
    var cropH = cropW / widget.aspectRatio;
    if (cropH > maxH) {
      cropH = maxH;
      cropW = cropH * widget.aspectRatio;
    }

    final frame = SizedBox(
      width: cropW,
      height: cropH,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.amber.withValues(alpha: 0.7),
            width: 1.2,
          ),
          borderRadius: widget.shape == ImageAdjustShape.circle
              ? BorderRadius.circular(cropW / 2)
              : BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: widget.shape == ImageAdjustShape.circle
              ? BorderRadius.circular(cropW / 2)
              : BorderRadius.circular(3),
          child: RepaintBoundary(
            key: _boundaryKey,
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 1,
              maxScale: 4,
              boundaryMargin: const EdgeInsets.all(220),
              child: SizedBox(
                width: cropW,
                height: cropH,
                child: Image.file(
                  File(widget.sourcePath),
                  fit: BoxFit.cover,
                  width: cropW,
                  height: cropH,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : _confirm,
            child: Text(
              _busy ? 'Saving…' : 'Done',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.amber),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: Center(child: frame)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  Text(
                    'Pinch to zoom · drag to pan · reposition inside the frame',
                    style: AppTypography.label.copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Reset',
                        onPressed: () => _transform.value = Matrix4.identity(),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                      IconButton(
                        tooltip: 'Zoom in',
                        onPressed: () {
                          final next = _transform.value.clone()
                            ..scaleByDouble(1.15, 1.15, 1, 1);
                          _transform.value = next;
                        },
                        icon: const Icon(Icons.zoom_in_rounded),
                      ),
                      IconButton(
                        tooltip: 'Zoom out',
                        onPressed: () {
                          final next = _transform.value.clone()
                            ..scaleByDouble(0.87, 0.87, 1, 1);
                          _transform.value = next;
                        },
                        icon: const Icon(Icons.zoom_out_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.borderSubtle),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _busy ? null : _confirm,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.amber,
                            foregroundColor: AppColors.textOnLight,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(_busy ? 'Saving…' : 'Use photo'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
