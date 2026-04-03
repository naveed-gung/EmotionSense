// ignore_for_file: avoid_print

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class ImageConverter {
  static InputImage? convertCameraImage(CameraImage image, int rotation) {
    try {
      final imageRotation = InputImageRotation.values.firstWhere(
        (element) => element.rawValue == rotation,
        orElse: () => InputImageRotation.rotation0deg,
      );

      final imageSize = Size(image.width.toDouble(), image.height.toDouble());

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

  static Uint8List? _yuv420toNV21(CameraImage image) {
    try {
      final width = image.width;
      final height = image.height;
      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];

      final int ySize = width * height;
      final int uvSize = (width * height) ~/ 4;

      final Uint8List nv21Buffer = Uint8List(ySize + 2 * uvSize);

      int bufferIndex = 0;
      for (int row = 0; row < height; row++) {
        final rowOffset = row * yPlane.bytesPerRow;
        for (int col = 0; col < width; col++) {
          nv21Buffer[bufferIndex++] = yPlane.bytes[rowOffset + col];
        }
      }

      final int uvWidth = width ~/ 2;
      final int uvHeight = height ~/ 2;
      final int uPixelStride = uPlane.bytesPerPixel ?? 1;
      final int vPixelStride = vPlane.bytesPerPixel ?? 1;

      for (int row = 0; row < uvHeight; row++) {
        final uRowOffset = row * uPlane.bytesPerRow;
        final vRowOffset = row * vPlane.bytesPerRow;

        for (int col = 0; col < uvWidth; col++) {
          final uIndex = uRowOffset + col * uPixelStride;
          final vIndex = vRowOffset + col * vPixelStride;

          nv21Buffer[bufferIndex++] = vPlane.bytes[vIndex];
          nv21Buffer[bufferIndex++] = uPlane.bytes[uIndex];
        }
      }

      return nv21Buffer;
    } catch (e) {
      print('❌ Error in YUV420 to NV21 conversion: $e');
      return null;
    }
  }
}
