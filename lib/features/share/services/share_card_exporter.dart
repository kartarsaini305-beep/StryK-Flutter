import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareCardExporter {
  const ShareCardExporter();

  Future<File> capturePng(GlobalKey key, {double pixelRatio = 3}) async {
    final context = key.currentContext;
    if (context == null) {
      throw StateError('Share card is not ready to export.');
    }
    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('Share card could not be rendered.');
    }
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      throw StateError('Share card image encoding failed.');
    }
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/stryk-${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes.buffer.asUint8List());
    return file;
  }

  Future<void> shareFile(File file, {String? text}) {
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: text ?? 'Just showed up. — StryK',
        subject: 'StryK',
      ),
    );
  }
}
