import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/data/services/camera_service.dart';
import 'package:emotion_sense/services/mlkit_face_service.dart';
import 'package:emotion_sense/services/unified_tflite_service.dart';
import 'package:emotion_sense/utils/image_preprocess.dart';
import 'package:emotion_sense/utils/image_converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FaceAttributes {
  FaceAttributes({
    required this.rect,
    required this.emotion,
    required this.confidence,
    required this.ageRange,
    required this.gender,
    this.ethnicity,
    this.rawSmileProb,
    this.leftEyeOpenProb,
    this.rightEyeOpenProb,
  });
  final Rect rect;
  final Emotion emotion;
  final double confidence;
  final String ageRange;
  final String gender;
  final String? ethnicity;
  final double? rawSmileProb;
  final double? leftEyeOpenProb;
  final double? rightEyeOpenProb;
}

class FaceAttributesProvider extends ChangeNotifier {
  FaceAttributesProvider(
    this._camera, {
    UnifiedTFLiteService? tfliteService,
    MLKitFaceService? mlkitService,
  })  : _tfliteService = tfliteService ?? UnifiedTFLiteService(),
        _mlkitService = mlkitService ?? MLKitFaceService();

  final CameraService _camera;
  final UnifiedTFLiteService _tfliteService;
  final MLKitFaceService _mlkitService;

  final List<FaceAttributes> _faces = [];
  List<FaceAttributes> get faces => List.unmodifiable(_faces);

  bool _running = false;
  bool _busy = false;
  int _skip = 0;
  int targetFps = 5;
  int _notifyThrottle = 0;
  int _lastFaceCount = 0;
  final Map<int, double> _emaConfidence = {};
  final double _emaAlpha = 0.4;
  StreamSubscription<CameraImage>? _imageStreamSubscription;

  // Emotion smoothing with history (from face_detection-main)
  final List<Emotion> _expressionHistory = [];
  static const int historyLength = 5;

  // Age/Gender smoothing history (reduce flickering)
  final List<int> _ageHistory = [];
  final List<String> _genderHistory = [];
  static const int attributeHistoryLength = 8;

  Future<void> start() async {
    if (_running) return;

    debugPrint('[FaceProvider] 🚀 Starting face detection...');

    // Initialize ML Kit for face detection
    if (!kIsWeb) {
      debugPrint('[FaceProvider] Initializing ML Kit...');
      await _mlkitService.initialize();
      debugPrint('[FaceProvider] Initializing TFLite...');
      // Initialize TFLite only for age/gender/ethnicity prediction (non-blocking fallback)
      try {
        await _tfliteService.initialize();
        debugPrint('[FaceProvider] ✅ All services initialized');
      } catch (e, stackTrace) {
        debugPrint(
            '[FaceProvider] ⚠️ TFLite initialization failed - will use ML Kit only: $e');
        debugPrint('[FaceProvider] Stack trace: $stackTrace');
        debugPrint(
            '[FaceProvider] ✅ Continuing with ML Kit for face/emotion detection');
      }
    }

    await _camera.startImageStream();
    _running = true;
    await _imageStreamSubscription?.cancel();
    _imageStreamSubscription = _camera.imageStream.listen(_onFrame);
    debugPrint('[FaceProvider] ✅ Image stream started');
  }

  Future<void> stop() async {
    debugPrint('[FaceProvider] Stopping face detection...');
    _running = false;
    await _imageStreamSubscription?.cancel();
    _imageStreamSubscription = null;
    await _camera.stopImageStream();
    _faces.clear();
    _emaConfidence.clear();
  }

  @override
  void dispose() {
    stop();
    _tfliteService.dispose();
    _mlkitService.dispose();
    super.dispose();
  }

  Future<void> _onFrame(CameraImage image) async {
    if (!_running) {
      debugPrint('[FaceProvider] ⚠️ _onFrame called but not running');
      return;
    }

    if (_busy) {
      // Don't spam logs for busy frames
      return;
    }

    final baseSkip = (30 / targetFps).round().clamp(1, 30);
    _skip = (_skip + 1) % baseSkip;
    if (_skip != 0) return;

    debugPrint(
        '[FaceProvider] 📸 Processing frame ${image.width}x${image.height}');

    _busy = true;
    try {
      // Check if ML Kit is initialized
      if (!_mlkitService.isInitialized) {
        debugPrint('[FaceProvider] ❌ ML Kit not initialized!');
        return;
      }

      // Use ML Kit for face detection (more reliable)
      final cameraDescription = _camera.description;
      if (cameraDescription == null) {
        debugPrint('[FaceProvider] ❌ No camera description available');
        return;
      }

      // Use ImageConverter for proper YUV420 to NV21 conversion
      final inputImage = ImageConverter.convertCameraImage(
        image,
        cameraDescription.sensorOrientation,
      );

      if (inputImage == null) {
        debugPrint('[FaceProvider] ❌ Failed to convert image');
        return;
      }

      // Get actual Face objects for frown detection
      final faceDetector = _mlkitService.faceDetector;
      if (faceDetector == null) {
        debugPrint('[FaceProvider] ❌ Face detector is null');
        return;
      }

      final faces = await faceDetector.processImage(inputImage);
      debugPrint('[FaceProvider] ML Kit returned ${faces.length} face(s)');

      _faces.clear();

      if (faces.isNotEmpty) {
        // Process only the largest face
        final largest = faces.reduce((a, b) =>
            (a.boundingBox.width * a.boundingBox.height) >
                    (b.boundingBox.width * b.boundingBox.height)
                ? a
                : b);

        // Normalize coordinates and handle front camera mirroring
        // For front camera, ML Kit coordinates need to be mirrored horizontally
        final isFrontCamera =
            cameraDescription.lensDirection == CameraLensDirection.front;

        // Get raw bounding box
        final rawBox = largest.boundingBox;

        // Expand bounding box to better center face (30-35% padding each direction)
        // This ensures full face capture and proper centering
        const expandFactorX = 0.30; // 30% horizontal expansion
        const expandFactorY =
            0.35; // 35% vertical expansion (more for forehead/chin)

        final expandX = rawBox.width * expandFactorX;
        final expandY = rawBox.height * expandFactorY;

        // Calculate expanded box with bounds checking
        final expandedLeft =
            (rawBox.left - expandX).clamp(0.0, image.width.toDouble());
        final expandedTop =
            (rawBox.top - expandY).clamp(0.0, image.height.toDouble());

        // Calculate max possible dimensions
        final maxWidth = image.width.toDouble() - expandedLeft;
        final maxHeight = image.height.toDouble() - expandedTop;

        final expandedWidth = (rawBox.width + 2 * expandX).clamp(1.0, maxWidth);
        final expandedHeight =
            (rawBox.height + 2 * expandY).clamp(1.0, maxHeight);

        // Normalize to 0-1 range
        var left = expandedLeft / image.width;
        final top = expandedTop / image.height;
        final width = expandedWidth / image.width;
        final height = expandedHeight / image.height;

        // Mirror horizontally for front camera
        if (isFrontCamera) {
          left = 1.0 - left - width;
        }

        final rect = Rect.fromLTWH(
          left.clamp(0.0, 1.0),
          top.clamp(0.0, 1.0),
          width.clamp(0.0, 1.0),
          height.clamp(0.0, 1.0),
        );

        debugPrint(
            '[FaceProvider] 📐 Raw: ${largest.boundingBox} -> Norm: $rect');

        // Use enhanced emotion detection with frown detection (pass Face object)
        final emotionStr = _mlkitService.inferEmotion(
          largest.smilingProbability,
          largest.leftEyeOpenProbability,
          largest.rightEyeOpenProbability,
          largest, // Pass Face object for frown detection
        );

        debugPrint(
            '[FaceProvider] 🎭 Raw emotion: $emotionStr | Smile: ${largest.smilingProbability?.toStringAsFixed(3)} | LeftEye: ${largest.leftEyeOpenProbability?.toStringAsFixed(2)} | RightEye: ${largest.rightEyeOpenProbability?.toStringAsFixed(2)}');

        final emotionMap = {
          'Happy': Emotion.happy,
          'Sad': Emotion.sad,
          'Angry': Emotion.angry,
          'Neutral': Emotion.neutral,
          'Surprised': Emotion.surprised,
        };
        final rawEmotion = emotionMap[emotionStr] ?? Emotion.neutral;

        // Add to emotion history for smoothing (from face_detection-main)
        _expressionHistory.add(rawEmotion);
        if (_expressionHistory.length > historyLength) {
          _expressionHistory.removeAt(0);
        }

        // Get smoothed emotion (most common in history)
        final smoothedEmotion = _getSmoothedEmotion();

        debugPrint(
            '[FaceProvider] ✅ Smoothed emotion: $smoothedEmotion (history: $_expressionHistory)');

        final inferredConfidence = MLKitFaceService.getEmotionConfidence(
          largest.smilingProbability,
        );

        // Try to get age/gender/ethnicity from TFLite
        String gender = 'Unknown';
        String ageRange = 'Unknown';
        String? ethnicity = 'Unknown';

        // Only try TFLite if attributes model is available
        if (_tfliteService.hasAttributes) {
          try {
            debugPrint('[FaceProvider] Running TFLite for age/gender...');

            final bb = Rect.fromLTWH(
              largest.boundingBox.left.clamp(0, image.width.toDouble()),
              largest.boundingBox.top.clamp(0, image.height.toDouble()),
              largest.boundingBox.width.clamp(1, image.width.toDouble()),
              largest.boundingBox.height.clamp(1, image.height.toDouble()),
            );

            // Prepare input for age model (200x200)
            final ageBuffer = Float32List(200 * 200 * 3);
            final ageInput = yuvToRgbInput(
              image.planes[0].bytes,
              image.planes.length > 1 ? image.planes[1].bytes : null,
              image.planes.length > 2 ? image.planes[2].bytes : null,
              image.width,
              image.height,
              image.planes.length > 1 ? image.planes[1].bytesPerRow : 0,
              image.planes.length > 1 ? image.planes[1].bytesPerPixel ?? 1 : 1,
              bb,
              200,
              200,
              ageBuffer,
            );

            // Prepare input for gender model (128x128)
            final genderBuffer = Float32List(128 * 128 * 3);
            final genderInput = yuvToRgbInput(
              image.planes[0].bytes,
              image.planes.length > 1 ? image.planes[1].bytes : null,
              image.planes.length > 2 ? image.planes[2].bytes : null,
              image.width,
              image.height,
              image.planes.length > 1 ? image.planes[1].bytesPerRow : 0,
              image.planes.length > 1 ? image.planes[1].bytesPerPixel ?? 1 : 1,
              bb,
              128,
              128,
              genderBuffer,
            );

            final attrs =
                await _tfliteService.predictAttributes(ageInput, genderInput);

            // Add to history for smoothing
            _ageHistory.add(attrs.age);
            _genderHistory.add(attrs.gender);
            if (_ageHistory.length > attributeHistoryLength) {
              _ageHistory.removeAt(0);
              _genderHistory.removeAt(0);
            }

            // Use smoothed values
            final smoothedAge = _getSmoothedAge();
            final smoothedGender = _getSmoothedGender();

            gender = smoothedGender;
            ageRange = '$smoothedAge';
            ethnicity = 'Unknown'; // No ethnicity model

            debugPrint(
                '[FaceProvider] ✅ TFLite results: Raw Age=${attrs.age}, Smoothed Age=$smoothedAge | Raw Gender=${attrs.gender}, Smoothed Gender=$smoothedGender');
          } catch (e, stackTrace) {
            debugPrint('[FaceProvider] ⚠️ Attribute prediction error: $e');
            debugPrint('[FaceProvider] Stack trace: $stackTrace');
            // Fall back to unknown values - at least face detection and emotion work
          }
        } else {
          debugPrint(
              '[FaceProvider] ⚠️ TFLite attributes model not available - Age/Gender/Ethnicity will show as "Unknown"');
          debugPrint(
              '[FaceProvider] ℹ️ Check console logs for TFLite model loading errors');
        }

        final key = _rectKey(rect);
        final prev = _emaConfidence[key];
        final smoothed = prev == null
            ? inferredConfidence
            : (prev * (1 - _emaAlpha) + inferredConfidence * _emaAlpha);
        _emaConfidence[key] = smoothed;

        _faces.add(FaceAttributes(
          rect: rect,
          emotion: smoothedEmotion,
          confidence: smoothed,
          ageRange: ageRange,
          gender: gender,
          ethnicity: ethnicity,
          rawSmileProb: largest.smilingProbability,
          leftEyeOpenProb: largest.leftEyeOpenProbability,
          rightEyeOpenProb: largest.rightEyeOpenProbability,
        ));

        debugPrint(
            '[FaceProvider] ✅ Face added: ${smoothedEmotion.label} (confidence: ${smoothed.toStringAsFixed(2)})');
      } else {
        // Clear history when no face detected
        _expressionHistory.clear();
        _ageHistory.clear();
        _genderHistory.clear();
        debugPrint('[FaceProvider] 👤 No faces detected in this frame');
      }

      final changedCount = _faces.length != _lastFaceCount;
      _lastFaceCount = _faces.length;

      _notifyThrottle = (_notifyThrottle + 1) % 2;
      if (_notifyThrottle == 0 || changedCount) {
        notifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint('[FaceProvider] ❌ Frame error: $e');
      debugPrint('[FaceProvider] Stack trace: $stackTrace');
    } finally {
      _busy = false;
    }
  }

  // Get most common emotion from history (from face_detection-main)
  Emotion _getSmoothedEmotion() {
    if (_expressionHistory.isEmpty) return Emotion.neutral;

    // Count occurrences
    final counts = <Emotion, int>{};
    for (var emotion in _expressionHistory) {
      counts[emotion] = (counts[emotion] ?? 0) + 1;
    }

    // Return most common
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // Get smoothed age using median (more robust than average)
  int _getSmoothedAge() {
    if (_ageHistory.isEmpty) return 0;

    final sorted = List<int>.from(_ageHistory)..sort();
    return sorted[sorted.length ~/ 2]; // Median value
  }

  // Get most common gender from history
  String _getSmoothedGender() {
    if (_genderHistory.isEmpty) return 'Unknown';

    final counts = <String, int>{};
    for (var gender in _genderHistory) {
      counts[gender] = (counts[gender] ?? 0) + 1;
    }

    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

int _rectKey(Rect r) {
  final l = (r.left * 1000).round();
  final t = (r.top * 1000).round();
  final w = (r.width * 1000).round();
  final h = (r.height * 1000).round();
  return l ^ (t << 8) ^ (w << 16) ^ (h << 24);
}
