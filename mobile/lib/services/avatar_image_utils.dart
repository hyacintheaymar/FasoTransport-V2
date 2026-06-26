import 'dart:typed_data';

import 'package:image/image.dart' as img;

Uint8List normalizeAvatarImage(Uint8List inputBytes, {int maxSize = 1024, int quality = 85}) {
  final decoded = img.decodeImage(inputBytes);
  if (decoded == null) {
    return inputBytes;
  }

  final side = decoded.width < decoded.height ? decoded.width : decoded.height;
  final cropX = ((decoded.width - side) / 2).round();
  final cropY = ((decoded.height - side) / 2).round();

  final cropped = img.copyCrop(decoded, x: cropX, y: cropY, width: side, height: side);
  final resized = side > maxSize ? img.copyResize(cropped, width: maxSize, height: maxSize) : cropped;

  return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
}