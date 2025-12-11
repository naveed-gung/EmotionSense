import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Google ML Kit face detection service for reliable face detection
/// with smiling probability for emotion inference.
class MLKitFaceService {
  FaceDetector? _faceDetector;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  FaceDetector? get faceDetector => _faceDetector; // Expose for direct access

  // Enhanced emotion detection parameters (tuned for better detection)
  double smileThresholdHappy = 0.70; // High threshold - only clear smiles
  double smileThresholdSad = 0.15; // Very low threshold for sad
  double frownYDifference = 8.0; // Higher threshold - require clear frown

  /// Update detection thresholds dynamically
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
        enableClassification: true, // For smiling/eye open probability
        enableLandmarks: true,
        enableContours: true, // Enable for mouth shape/frown detection
        enableTracking: true, // Track faces across frames
        performanceMode:
            FaceDetectorMode.accurate, // More accurate for emotion detection
        minFaceSize: 0.15, // Detect faces that are at least 15% of image width
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

  /// Process a camera image and detect faces
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

  /// Convert CameraImage to InputImage for ML Kit
  InputImage? _convertCameraImage(CameraImage image, CameraDescription camera) {
    try {
      debugPrint(
          '[MLKit] 📸 Converting image: ${image.width}x${image.height}, format=${image.format.raw}');

      // Get the rotation based on camera sensor orientation
      final rotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation);
      if (rotation == null) {
        debugPrint('[MLKit] ❌ Invalid rotation: ${camera.sensorOrientation}');
        return null;
      }
      debugPrint('[MLKit] Rotation: $rotation (${camera.sensorOrientation}°)');

      // Handle different platforms and formats
      final planes = image.planes;
      if (planes.isEmpty) {
        debugPrint('[MLKit] ❌ No image planes available');
        return null;
      }
      debugPrint(
          '[MLKit] Planes: ${planes.length}, Y plane: ${planes[0].bytes.length} bytes');

      // For Android YUV_420_888, we need to convert to NV21
      // Format code 35 is YUV_420_888 on Android
      final WriteBuffer allBytes = WriteBuffer();

      if (planes.length == 1) {
        // Single plane - already in correct format (e.g., BGRA on iOS)
        allBytes.putUint8List(planes[0].bytes);
        debugPrint('[MLKit] Single plane format detected');
      } else if (planes.length == 3) {
        // YUV_420_888 - need to convert to NV21
        // NV21 format: YYYYYYYY VUVU
        debugPrint('[MLKit] YUV_420_888 detected, converting to NV21...');

        // Add Y plane
        allBytes.putUint8List(planes[0].bytes);

        // Interleave V and U planes (NV21 is Y + VU interleaved)
        final int uvRowStride = planes[1].bytesPerRow;
        final int uvPixelStride = planes[1].bytesPerPixel ?? 1;
        final int width = image.width;
        final int height = image.height;

        debugPrint(
            '[MLKit] UV stride: $uvRowStride, pixel stride: $uvPixelStride');

        if (uvPixelStride == 1) {
          // Tightly packed - just concatenate V then U
          allBytes.putUint8List(planes[2].bytes); // V
          allBytes.putUint8List(planes[1].bytes); // U
        } else {
          // Need to interleave V and U
          final int uvWidth = width ~/ 2;
          final int uvHeight = height ~/ 2;

          for (int y = 0; y < uvHeight; y++) {
            for (int x = 0; x < uvWidth; x++) {
              final int uvIndex = y * uvRowStride + x * uvPixelStride;
              allBytes.putUint8(planes[2].bytes[uvIndex]); // V
              allBytes.putUint8(planes[1].bytes[uvIndex]); // U
            }
          }
        }
      } else {
        debugPrint('[MLKit] ❌ Unexpected number of planes: ${planes.length}');
        return null;
      }

      final bytes = allBytes.done().buffer.asUint8List();
      debugPrint('[MLKit] ✅ Converted ${bytes.length} bytes total');

      // Determine the format
      InputImageFormat inputFormat;
      if (planes.length == 1) {
        inputFormat = InputImageFormat.bgra8888; // iOS typically
      } else {
        inputFormat = InputImageFormat.nv21; // Android YUV converted to NV21
      }

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

  /// Infer emotion from face attributes with advanced frown detection
  String inferEmotion(double? smilingProbability, double? leftEyeOpen,
      double? rightEyeOpen, Face? face) {
    if (smilingProbability == null) return 'Neutral';

    // Check for frown if face data is available
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

    // PRIORITY 1: HAPPY - Clear smile (high threshold)
    if (smilingProbability > smileThresholdHappy) {
      debugPrint('[MLKit] 😊 HAPPY - Clear smile detected');
      return 'Happy';
    }

    // PRIORITY 2: SAD - BOTH very low smile AND frown (more strict)
    // Require both conditions to avoid false sad detection
    if (smilingProbability < 0.15 && isFrowning) {
      debugPrint(
          '[MLKit] 😢 SAD - Very low smile (${smilingProbability.toStringAsFixed(3)}) AND frown detected');
      return 'Sad';
    }

    // Very low smile + narrow eyes = Angry (but not sad)
    if (smilingProbability < 0.15 && !isFrowning) {
      final avgEyeOpen = ((leftEyeOpen ?? 0.5) + (rightEyeOpen ?? 0.5)) / 2;
      // Squinting/narrow eyes (but not closed) suggests anger
      if (avgEyeOpen > 0.2 && avgEyeOpen < 0.7) {
        debugPrint(
            '[MLKit] 😠 ANGRY - Low smile: ${smilingProbability.toStringAsFixed(3)}, narrow eyes');
        return 'Angry';
      }
    }

    // Check for surprised (wide eyes with moderate smile)
    if (smilingProbability > 0.3 && smilingProbability < 0.65) {
      final avgEyeOpen = ((leftEyeOpen ?? 0.5) + (rightEyeOpen ?? 0.5)) / 2;
      if (avgEyeOpen > 0.85) {
        debugPrint('[MLKit] 😲 SURPRISED - Wide eyes, moderate smile');
        return 'Surprised';
      }
    }

    // Default to Neutral for everything else
    debugPrint(
        '[MLKit] 😐 NEUTRAL - Smile: ${smilingProbability.toStringAsFixed(3)} (no strong emotion detected)');
    return 'Neutral';
  }

  /// Detect frown using mouth landmarks and contours
  Map<String, dynamic> _detectFrown(Face face) {
    // Try using landmarks first (more reliable)
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];

    if (leftMouth != null && rightMouth != null && bottomMouth != null) {
      final leftPos = leftMouth.position;
      final rightPos = rightMouth.position;
      final bottomPos = bottomMouth.position;

      // Calculate average corner Y position
      final avgCornerY = (leftPos.y + rightPos.y) / 2;

      // For a frown, corners should be HIGHER than bottom (pointing down)
      final yDifference = avgCornerY - bottomPos.y;

      return {
        'isFrowning': yDifference > frownYDifference,
        'yDifference': yDifference
      };
    }

    // Fallback: Try contours
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
        'yDifference': yDifference
      };
    }

    return {'isFrowning': false, 'yDifference': 0.0};
  }

  /// Get confidence for the inferred emotion
  static double getEmotionConfidence(double? smilingProbability) {
    if (smilingProbability == null) return 0.5;

    // Strong signals = high confidence
    if (smilingProbability > 0.8 || smilingProbability < 0.1) {
      return 0.9;
    }
    // Moderate signals = moderate confidence
    if (smilingProbability > 0.5 || smilingProbability < 0.3) {
      return 0.7;
    }
    // Ambiguous signals = lower confidence
    return 0.5;
  }

  void dispose() {
    _faceDetector?.close();
    _faceDetector = null;
    _isInitialized = false;
    debugPrint('[MLKit] Disposed');
  }
}

/// Simplified face data class from ML Kit detection
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

  /// Normalized bounding box (0-1 range) given image dimensions
  Rect getNormalizedRect(int imageWidth, int imageHeight) {
    return Rect.fromLTWH(
      (boundingBox.left / imageWidth).clamp(0.0, 1.0),
      (boundingBox.top / imageHeight).clamp(0.0, 1.0),
      (boundingBox.width / imageWidth).clamp(0.0, 1.0),
      (boundingBox.height / imageHeight).clamp(0.0, 1.0),
    );
  }
}
