// ignore_for_file: avoid_print

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Image converter utility for converting CameraImage to InputImage
/// Handles YUV420 to NV21 conversion for Google ML Kit
class ImageConverter {
  /// Convert CameraImage to InputImage for ML Kit processing
  static InputImage? convertCameraImage(CameraImage image, int rotation) {
    try {
      final imageRotation = InputImageRotation.values.firstWhere(
        (element) => element.rawValue == rotation,
        orElse: () => InputImageRotation.rotation0deg,
      );

      final imageSize = Size(image.width.toDouble(), image.height.toDouble());

      // Convert YUV420 to NV21 since ML Kit supports it
      if (image.format.group == ImageFormatGroup.yuv420) {
        final Uint8List? nv21Buffer = _yuv420toNV21(image);
        if (nv21Buffer == null) {
          print('❌ Failed to convert YUV420 to NV21');
          return null;
        }

        final metadata = InputImageMetadata(
          size: imageSize,
          rotation: imageRotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width,
        );

        print(
          '📸 Converting YUV420->NV21 image: ${image.width}x${image.height}, '
          'Rotation: ${imageRotation.name}, '
          'Format: NV21',
        );

        return InputImage.fromBytes(bytes: nv21Buffer, metadata: metadata);
      }

      print('❌ Unsupported image format: ${image.format.group}');
      return null;
    } catch (e) {
      print('❌ Error converting image: $e');
      return null;
    }
  }

  /// Convert YUV420 image to NV21 format
  static Uint8List? _yuv420toNV21(CameraImage image) {
    try {
      final width = image.width;
      final height = image.height;
      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];

      final int ySize = width * height;
      final int uvSize = (width * height) ~/ 4;

      // Create output buffer
      final Uint8List nv21Buffer = Uint8List(ySize + 2 * uvSize);

      // Copy Y plane as is
      for (int row = 0; row < height; row++) {
        for (int col = 0; col < width; col++) {
          final int yIndex = row * width + col;
          final int yValue = yPlane.bytes[row * yPlane.bytesPerRow + col];
          nv21Buffer[yIndex] = yValue;
        }
      }

      // Interleave V and U planes (NV21 format: Y + VU interleaved)
      int nvIndex = ySize;
      final int uvRowStride = uPlane.bytesPerRow;
      final int uvPixelStride = uPlane.bytesPerPixel!;

      for (int row = 0; row < height ~/ 2; row++) {
        for (int col = 0; col < width ~/ 2; col++) {
          final int uvIndex = row * uvRowStride + col * uvPixelStride;
          nv21Buffer[nvIndex++] = vPlane.bytes[uvIndex]; // V first
          nv21Buffer[nvIndex++] = uPlane.bytes[uvIndex]; // then U
        }
      }

      return nv21Buffer;
    } catch (e) {
      print('❌ Error converting YUV420 to NV21: $e');
      return null;
    }
  }
}
