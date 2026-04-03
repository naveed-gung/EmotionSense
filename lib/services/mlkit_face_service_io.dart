import 'dart:async';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class MLKitFaceService {
  FaceDetector? _faceDetector;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  FaceDetector? get faceDetector => _faceDetector;

  double smileThresholdHappy = 0.70;
  double smileThresholdSad = 0.15;
  double frownYDifference = 8.0;

  void updateThresholds({
    double? happy,
    double? sad,
    double? frownY,
  }) {
    if (happy != null) smileThresholdHappy = happy;
    if (sad != null) smileThresholdSad = sad;
    if (frownY != null) frownYDifference = frownY;
    debugPrint(
        '[MLKit] 📊 Thresholds updated: Happy=$smileThresholdHappy, Sad=$smileThresholdSad, FrownY=$frownYDifference');
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final options = FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        enableContours: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.15,
      );

      _faceDetector = FaceDetector(options: options);
      _isInitialized = true;
      debugPrint(
          '[MLKit] ✅ Face detector initialized with enhanced emotion detection');
    } catch (e, stackTrace) {
      debugPrint('[MLKit] ❌ init error: $e');
      debugPrint('[MLKit] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<MLKitFace>> detectFaces(
      CameraImage image, CameraDescription camera) async {
    if (!_isInitialized || _faceDetector == null) {
      debugPrint('[MLKit] ❌ detectFaces: Not initialized');
      return [];
    }

    try {
      final inputImage = _convertCameraImage(image, camera);
      if (inputImage == null) {
        debugPrint('[MLKit] ❌ detectFaces: Failed to convert image');
        return [];
      }

      final faces = await _faceDetector!.processImage(inputImage);
      debugPrint('[MLKit] ✅ detectFaces: Found ${faces.length} face(s)');

      if (faces.isNotEmpty) {
        final face = faces.first;
        debugPrint(
            '[MLKit]   Smile: ${face.smilingProbability?.toStringAsFixed(2)}');
        debugPrint(
            '[MLKit]   LeftEye: ${face.leftEyeOpenProbability?.toStringAsFixed(2)}');
        debugPrint(
            '[MLKit]   RightEye: ${face.rightEyeOpenProbability?.toStringAsFixed(2)}');
      }

      return faces
          .map((face) => MLKitFace(
                boundingBox: face.boundingBox,
                smilingProbability: face.smilingProbability,
                leftEyeOpenProbability: face.leftEyeOpenProbability,
                rightEyeOpenProbability: face.rightEyeOpenProbability,
                headEulerAngleX: face.headEulerAngleX,
                headEulerAngleY: face.headEulerAngleY,
                headEulerAngleZ: face.headEulerAngleZ,
                trackingId: face.trackingId,
              ))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('[MLKit] ❌ detectFaces error: $e');
      debugPrint('[MLKit] Stack trace: $stackTrace');
      return [];
    }
  }

  InputImage? _convertCameraImage(CameraImage image, CameraDescription camera) {
    try {
      debugPrint(
          '[MLKit] 📸 Converting image: ${image.width}x${image.height}, format=${image.format.raw}');

      final rotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation);
      if (rotation == null) {
        debugPrint('[MLKit] ❌ Invalid rotation: ${camera.sensorOrientation}');
        return null;
      }
      debugPrint('[MLKit] Rotation: $rotation (${camera.sensorOrientation}°)');

      final planes = image.planes;
      if (planes.isEmpty) {
        debugPrint('[MLKit] ❌ No image planes available');
        return null;
      }
      debugPrint(
          '[MLKit] Planes: ${planes.length}, Y plane: ${planes[0].bytes.length} bytes');

      final WriteBuffer allBytes = WriteBuffer();

      if (planes.length == 1) {
        allBytes.putUint8List(planes[0].bytes);
        debugPrint('[MLKit] Single plane format detected');
      } else if (planes.length == 3) {
        debugPrint('[MLKit] YUV_420_888 detected, converting to NV21...');

        allBytes.putUint8List(planes[0].bytes);

        final int uvRowStride = planes[1].bytesPerRow;
        final int uvPixelStride = planes[1].bytesPerPixel ?? 1;
        final int width = image.width;
        final int height = image.height;

        debugPrint(
            '[MLKit] UV stride: $uvRowStride, pixel stride: $uvPixelStride');

        if (uvPixelStride == 1) {
          allBytes.putUint8List(planes[2].bytes);
          allBytes.putUint8List(planes[1].bytes);
        } else {
          final int uvWidth = width ~/ 2;
          final int uvHeight = height ~/ 2;

          for (int y = 0; y < uvHeight; y++) {
            for (int x = 0; x < uvWidth; x++) {
              final int uvIndex = y * uvRowStride + x * uvPixelStride;
              allBytes.putUint8(planes[2].bytes[uvIndex]);
              allBytes.putUint8(planes[1].bytes[uvIndex]);
            }
          }
        }
      } else {
        debugPrint('[MLKit] ❌ Unexpected number of planes: ${planes.length}');
        return null;
      }

      final bytes = allBytes.done().buffer.asUint8List();
      debugPrint('[MLKit] ✅ Converted ${bytes.length} bytes total');

      final inputFormat =
          planes.length == 1 ? InputImageFormat.bgra8888 : InputImageFormat.nv21;

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: inputFormat,
        bytesPerRow: planes[0].bytesPerRow,
      );

      debugPrint(
          '[MLKit] Metadata: format=$inputFormat, size=${metadata.size}, rotation=${metadata.rotation}');
      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (e, stackTrace) {
      debugPrint('[MLKit] ❌ _convertCameraImage error: $e');
      debugPrint('[MLKit] Stack trace: $stackTrace');
      return null;
    }
  }

  String inferEmotion(double? smilingProbability, double? leftEyeOpen,
      double? rightEyeOpen, Face? face) {
    if (smilingProbability == null) return 'Neutral';

    bool isFrowning = false;
    if (face != null) {
      final frownData = _detectFrown(face);
      isFrowning = frownData['isFrowning'] as bool;
      final yDiff = frownData['yDifference'] as double;
      debugPrint(
          '[MLKit] Frown detection: $isFrowning, YDiff: ${yDiff.toStringAsFixed(1)}');
    }

    debugPrint(
        '[MLKit] 📊 SmileProb: ${smilingProbability.toStringAsFixed(3)}, Frown: $isFrowning');

    if (smilingProbability > smileThresholdHappy) {
      debugPrint('[MLKit] 😊 HAPPY - Clear smile detected');
      return 'Happy';
    }

    if (smilingProbability < 0.15 && isFrowning) {
      debugPrint(
          '[MLKit] 😢 SAD - Very low smile (${smilingProbability.toStringAsFixed(3)}) AND frown detected');
      return 'Sad';
    }

    if (smilingProbability < 0.15 && !isFrowning) {
      final avgEyeOpen = ((leftEyeOpen ?? 0.5) + (rightEyeOpen ?? 0.5)) / 2;
      if (avgEyeOpen > 0.2 && avgEyeOpen < 0.7) {
        debugPrint(
            '[MLKit] 😠 ANGRY - Low smile: ${smilingProbability.toStringAsFixed(3)}, narrow eyes');
        return 'Angry';
      }
    }

    if (smilingProbability > 0.3 && smilingProbability < 0.65) {
      final avgEyeOpen = ((leftEyeOpen ?? 0.5) + (rightEyeOpen ?? 0.5)) / 2;
      if (avgEyeOpen > 0.85) {
        debugPrint('[MLKit] 😲 SURPRISED - Wide eyes, moderate smile');
        return 'Surprised';
      }
    }

    debugPrint(
        '[MLKit] 😐 NEUTRAL - Smile: ${smilingProbability.toStringAsFixed(3)} (no strong emotion detected)');
    return 'Neutral';
  }

  Map<String, dynamic> _detectFrown(Face face) {
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];

    if (leftMouth != null && rightMouth != null && bottomMouth != null) {
      final leftPos = leftMouth.position;
      final rightPos = rightMouth.position;
      final bottomPos = bottomMouth.position;

      final avgCornerY = (leftPos.y + rightPos.y) / 2;
      final yDifference = avgCornerY - bottomPos.y;

      return {
        'isFrowning': yDifference > frownYDifference,
        'yDifference': yDifference,
      };
    }

    final mouthBottom = face.contours[FaceContourType.lowerLipBottom];

    if (mouthBottom != null && mouthBottom.points.length >= 3) {
      final points = mouthBottom.points;
      final leftCorner = points.first;
      final rightCorner = points.last;
      final centerIndex = points.length ~/ 2;
      final center = points[centerIndex];

      final avgCornerY = (leftCorner.y + rightCorner.y) / 2;
      final yDifference = avgCornerY - center.y;

      return {
        'isFrowning': yDifference > frownYDifference,
        'yDifference': yDifference,
      };
    }

    return {'isFrowning': false, 'yDifference': 0.0};
  }

  static double getEmotionConfidence(double? smilingProbability) {
    if (smilingProbability == null) return 0.5;

    if (smilingProbability > 0.8 || smilingProbability < 0.1) {
      return 0.9;
    }
    if (smilingProbability > 0.5 || smilingProbability < 0.3) {
      return 0.7;
    }
    return 0.5;
  }

  void dispose() {
    _faceDetector?.close();
    _faceDetector = null;
    _isInitialized = false;
    debugPrint('[MLKit] Disposed');
  }
}

class MLKitFace {
  final Rect boundingBox;
  final double? smilingProbability;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  final double? headEulerAngleX;
  final double? headEulerAngleY;
  final double? headEulerAngleZ;
  final int? trackingId;

  MLKitFace({
    required this.boundingBox,
    this.smilingProbability,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    this.headEulerAngleX,
    this.headEulerAngleY,
    this.headEulerAngleZ,
    this.trackingId,
  });
}