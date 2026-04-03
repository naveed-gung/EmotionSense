import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Normalization modes for model input preprocessing.
enum NormalizationMode {
  /// (x - 127.5) / 128.0 → range [-1, 1] (MobileNet-style)
  mobilenet,

  /// x / 255.0 → range [0, 1] (standard for UTKFace-derived models)
  standard,

  /// No normalization — raw [0, 255] cast to float
  none,
}

void _writeNormalizedRgb(
  Float32List out,
  int outIdx,
  double r,
  double g,
  double b,
  NormalizationMode mode,
) {
  switch (mode) {
    case NormalizationMode.standard:
      out[outIdx] = r / 255.0;
      out[outIdx + 1] = g / 255.0;
      out[outIdx + 2] = b / 255.0;
    case NormalizationMode.mobilenet:
      out[outIdx] = (r - 127.5) / 128.0;
      out[outIdx + 1] = (g - 127.5) / 128.0;
      out[outIdx + 2] = (b - 127.5) / 128.0;
    case NormalizationMode.none:
      out[outIdx] = r;
      out[outIdx + 1] = g;
      out[outIdx + 2] = b;
  }
}

/// Convert Y plane to grayscale Float32 input [1, H, W, 1] flattened
/// normalized by /255 for model input. Returns a flat Float32List size H*W.
Float32List yuvToGrayscaleInput(
  Uint8List yBytes,
  int width,
  int height,
  Rect bb,
  int outW,
  int outH,
) {
  final left = bb.left.clamp(0.0, width.toDouble()).toInt();
  final top = bb.top.clamp(0.0, height.toDouble()).toInt();
  final right = (bb.right.clamp(0.0, width.toDouble())).toInt();
  final bottom = (bb.bottom.clamp(0.0, height.toDouble())).toInt();
  final cropW = math.max(1, right - left);
  final cropH = math.max(1, bottom - top);
  final out = Float32List(outH * outW);
  for (int oy = 0; oy < outH; oy++) {
    final sy = top + (oy * cropH / outH).floor();
    for (int ox = 0; ox < outW; ox++) {
      final sx = left + (ox * cropW / outW).floor();
      final yIndex = sy * width + sx;
      if (yIndex < yBytes.length) {
        final yVal = yBytes[yIndex];
        out[oy * outW + ox] = yVal / 255.0;
      }
    }
  }
  return out;
}

/// Convert YUV420 to RGB Float32 input [1, H, W, 3] flattened.
/// Supports configurable normalization via [mode].
/// Returns a flat Float32List size H*W*3.
Float32List yuvToRgbInput(
  Uint8List yBytes,
  Uint8List? uBytes,
  Uint8List? vBytes,
  int width,
  int height,
  int uvRowStride,
  int uvPixelStride,
  Rect bb,
  int outW,
  int outH, {
  NormalizationMode mode = NormalizationMode.standard,
  Float32List? outBuffer,
}) {
  final left = bb.left.clamp(0.0, width.toDouble()).toInt();
  final top = bb.top.clamp(0.0, height.toDouble()).toInt();
  final right = (bb.right.clamp(0.0, width.toDouble())).toInt();
  final bottom = (bb.bottom.clamp(0.0, height.toDouble())).toInt();
  final cropW = math.max(1, right - left);
  final cropH = math.max(1, bottom - top);

  final needed = outH * outW * 3;
  final out = (outBuffer != null && outBuffer.length == needed)
      ? outBuffer
      : Float32List(needed);
  int outIdx = 0;
  for (int oy = 0; oy < outH; oy++) {
    final sy = top + (oy * cropH / outH).floor();
    for (int ox = 0; ox < outW; ox++) {
      final sx = left + (ox * cropW / outW).floor();
      final yIndex = sy * width + sx;
      final y = (yIndex < yBytes.length) ? yBytes[yIndex].toDouble() : 0.0;
      double r, g, b;
      if (uBytes != null && vBytes != null) {
        final uvX = (sx / 2).floor();
        final uvY = (sy / 2).floor();
        final uvIndex = uvY * uvRowStride + uvX * uvPixelStride;
        if (uvIndex < uBytes.length && uvIndex < vBytes.length) {
          final u = uBytes[uvIndex].toDouble() - 128.0;
          final v = vBytes[uvIndex].toDouble() - 128.0;
          r = y + 1.402 * v;
          g = y - 0.344136 * u - 0.714136 * v;
          b = y + 1.772 * u;
        } else {
          r = g = b = y;
        }
      } else {
        r = g = b = y;
      }
      r = r.clamp(0.0, 255.0);
      g = g.clamp(0.0, 255.0);
      b = b.clamp(0.0, 255.0);

      _writeNormalizedRgb(out, outIdx, r, g, b, mode);
      outIdx += 3;
    }
  }
  return out;
}

/// Convert BGRA8888 bytes to RGB Float32 input [1, H, W, 3] flattened.
/// Used by iOS camera streams where frames arrive as a single BGRA plane.
Float32List bgra8888ToRgbInput(
  Uint8List bgraBytes,
  int width,
  int height,
  int bytesPerRow,
  Rect bb,
  int outW,
  int outH, {
  NormalizationMode mode = NormalizationMode.standard,
  Float32List? outBuffer,
}) {
  final left = bb.left.clamp(0.0, width.toDouble()).toInt();
  final top = bb.top.clamp(0.0, height.toDouble()).toInt();
  final right = (bb.right.clamp(0.0, width.toDouble())).toInt();
  final bottom = (bb.bottom.clamp(0.0, height.toDouble())).toInt();
  final cropW = math.max(1, right - left);
  final cropH = math.max(1, bottom - top);

  final needed = outH * outW * 3;
  final out = (outBuffer != null && outBuffer.length == needed)
      ? outBuffer
      : Float32List(needed);

  int outIdx = 0;
  for (int oy = 0; oy < outH; oy++) {
    final sy = top + (oy * cropH / outH).floor();
    for (int ox = 0; ox < outW; ox++) {
      final sx = left + (ox * cropW / outW).floor();
      final pixelIndex = sy * bytesPerRow + sx * 4;

      double r = 0.0;
      double g = 0.0;
      double b = 0.0;

      if (pixelIndex + 2 < bgraBytes.length) {
        b = bgraBytes[pixelIndex].toDouble();
        g = bgraBytes[pixelIndex + 1].toDouble();
        r = bgraBytes[pixelIndex + 2].toDouble();
      }

      _writeNormalizedRgb(out, outIdx, r, g, b, mode);
      outIdx += 3;
    }
  }

  return out;
}
