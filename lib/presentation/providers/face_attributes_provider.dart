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
    this.headEulerAngleX,
    this.headEulerAngleY,
    this.headEulerAngleZ,
    this.trackingId,
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
  final double? headEulerAngleX;
  final double? headEulerAngleY;
  final double? headEulerAngleZ;
  final int? trackingId;
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
  int targetFps = 8;
  int _notifyThrottle = 0;
  int _lastFaceCount = 0;
  final Map<int, double> _emaConfidence = {};
  final double _emaAlpha = 0.4;
  StreamSubscription<CameraImage>? _imageStreamSubscription;

  // Performance tracking
  final Stopwatch _frameStopwatch = Stopwatch();
  double _lastLatencyMs = 0;
  double _currentFps = 0;
  int _fpsFrameCount = 0;
  DateTime _fpsLastTime = DateTime.now();
  double get lastLatencyMs => _lastLatencyMs;
  double get currentFps => _currentFps;

  // Emotion smoothing — per-face by trackingId
  final Map<int, List<Emotion>> _expressionHistoryMap = {};
  final Map<int, List<int>> _ageHistoryMap = {};
  final Map<int, List<String>> _genderHistoryMap = {};
  final Map<int, List<String>> _ethnicityHistoryMap = {};
  static const int historyLength = 5;
  static const int attributeHistoryLength = 8;

  // Emotion alert callback
  void Function(Emotion emotion, double confidence, int faceIndex)?
      onEmotionAlert;
  Emotion? _alertEmotion;
  double _alertThreshold = 0.7;

  void setEmotionAlert(Emotion? emotion, double threshold) {
    _alertEmotion = emotion;
    _alertThreshold = threshold;
  }

  Future<void> start() async {
    if (_running) return;

    if (kIsWeb) {
      _running = true;
      _faces.clear();
      notifyListeners();
      return;
    }

    await _mlkitService.initialize();
    try {
      await _tfliteService.initialize();
    } catch (e) {
      debugPrint('[FaceProvider] TFLite init failed, ML Kit only: $e');
    }

    await _camera.startImageStream();
    _running = true;
    await _imageStreamSubscription?.cancel();
    _imageStreamSubscription = _camera.imageStream.listen(_onFrame);
  }

  Future<void> stop() async {
    _running = false;
    if (kIsWeb) {
      _faces.clear();
      _emaConfidence.clear();
      notifyListeners();
      return;
    }
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

  /// Transform ML Kit bounding box from rotated image space to raw camera frame space.
  /// ML Kit processes an NV21 image with specified rotation, so its bounding box
  /// is in the rotated coordinate system. We need to map it back to the original
  /// raw frame coordinates for cropping.
  Rect _transformBboxToRawFrame(
    Rect mlKitBox,
    int imageWidth,
    int imageHeight,
    int sensorOrientation,
    bool isFrontCamera,
  ) {
    double left = mlKitBox.left;
    double top = mlKitBox.top;
    double width = mlKitBox.width;
    double height = mlKitBox.height;

    // The ML Kit bounding box is already in the raw frame coordinate space
    // because we pass the rotation in metadata. ML Kit accounts for it internally.
    // However, on some Android devices the coordinates may need clamping.

    // Clamp to valid frame dimensions
    left = left.clamp(0.0, imageWidth.toDouble());
    top = top.clamp(0.0, imageHeight.toDouble());
    width = width.clamp(1.0, imageWidth.toDouble() - left);
    height = height.clamp(1.0, imageHeight.toDouble() - top);

    // Expand bounding box by 15% for better face capture
    final expandX = width * 0.15;
    final expandY = height * 0.20;

    left = (left - expandX).clamp(0.0, imageWidth.toDouble());
    top = (top - expandY).clamp(0.0, imageHeight.toDouble());
    width = (width + 2 * expandX).clamp(1.0, imageWidth.toDouble() - left);
    height = (height + 2 * expandY).clamp(1.0, imageHeight.toDouble() - top);

    return Rect.fromLTWH(left, top, width, height);
  }

  Future<void> _onFrame(CameraImage image) async {
    if (!_running || _busy) return;

    final baseSkip = (30 / targetFps).round().clamp(1, 30);
    _skip = (_skip + 1) % baseSkip;
    if (_skip != 0) return;

    _busy = true;
    _frameStopwatch.reset();
    _frameStopwatch.start();

    try {
      if (!_mlkitService.isInitialized) return;

      final cameraDescription = _camera.description;
      if (cameraDescription == null) return;

      final inputImage = ImageConverter.convertCameraImage(
        image,
        cameraDescription.sensorOrientation,
      );
      if (inputImage == null) return;

      final faceDetector = _mlkitService.faceDetector;
      if (faceDetector == null) return;

      final faces = await faceDetector.processImage(inputImage);
      _faces.clear();

      // Sort faces by area (largest first) and process up to 5
      final sortedFaces = List.of(faces);
      sortedFaces.sort((a, b) {
        final areaA = a.boundingBox.width * a.boundingBox.height;
        final areaB = b.boundingBox.width * b.boundingBox.height;
        return areaB.compareTo(areaA);
      });
      final facesToProcess = sortedFaces.take(5).toList();

      final activeTrackingIds = <int>{};

      for (int fi = 0; fi < facesToProcess.length; fi++) {
        final face = facesToProcess[fi];
        final trackingId = face.trackingId ?? fi;
        activeTrackingIds.add(trackingId);

        final isFrontCamera =
            cameraDescription.lensDirection == CameraLensDirection.front;

        // Normalized bounding box for UI overlay
        final rawBox = face.boundingBox;
        const expandFactorX = 0.30;
        const expandFactorY = 0.35;
        final expandX = rawBox.width * expandFactorX;
        final expandY = rawBox.height * expandFactorY;

        final expandedLeft =
            (rawBox.left - expandX).clamp(0.0, image.width.toDouble());
        final expandedTop =
            (rawBox.top - expandY).clamp(0.0, image.height.toDouble());
        final maxWidth = image.width.toDouble() - expandedLeft;
        final maxHeight = image.height.toDouble() - expandedTop;
        final expandedWidth = (rawBox.width + 2 * expandX).clamp(1.0, maxWidth);
        final expandedHeight =
            (rawBox.height + 2 * expandY).clamp(1.0, maxHeight);

        var left = expandedLeft / image.width;
        final top = expandedTop / image.height;
        final width = expandedWidth / image.width;
        final height = expandedHeight / image.height;

        if (isFrontCamera) {
          left = 1.0 - left - width;
        }

        final rect = Rect.fromLTWH(
          left.clamp(0.0, 1.0),
          top.clamp(0.0, 1.0),
          width.clamp(0.0, 1.0),
          height.clamp(0.0, 1.0),
        );

        // Emotion from ML Kit heuristics
        final emotionStr = _mlkitService.inferEmotion(
          face.smilingProbability,
          face.leftEyeOpenProbability,
          face.rightEyeOpenProbability,
          face,
        );

        final emotionMap = {
          'Happy': Emotion.happy,
          'Sad': Emotion.sad,
          'Angry': Emotion.angry,
          'Neutral': Emotion.neutral,
          'Surprised': Emotion.surprised,
        };
        final rawEmotion = emotionMap[emotionStr] ?? Emotion.neutral;

        // Per-face emotion smoothing
        _expressionHistoryMap.putIfAbsent(trackingId, () => []);
        _expressionHistoryMap[trackingId]!.add(rawEmotion);
        if (_expressionHistoryMap[trackingId]!.length > historyLength) {
          _expressionHistoryMap[trackingId]!.removeAt(0);
        }
        final smoothedEmotion = _getSmoothedEmotionFor(trackingId);

        final inferredConfidence = MLKitFaceService.getEmotionConfidence(
          face.smilingProbability,
        );

        String gender = 'Unknown';
        String ageRange = '~';
        String? ethnicity = 'Unknown';

        if (_tfliteService.hasAttributes) {
          try {
            final cropBb = _transformBboxToRawFrame(
              face.boundingBox,
              image.width,
              image.height,
              cameraDescription.sensorOrientation,
              isFrontCamera,
            );

            final hasUV = image.planes.length > 2;
            final uBytes = hasUV ? image.planes[1].bytes : null;
            final vBytes = hasUV ? image.planes[2].bytes : null;
            final uvRowStride = hasUV ? image.planes[1].bytesPerRow : 0;
            final uvPixelStride =
                hasUV ? (image.planes[1].bytesPerPixel ?? 1) : 1;

            final ageSz = _tfliteService.ageInputSize;
            final ageInput = yuvToRgbInput(
              image.planes[0].bytes,
              uBytes,
              vBytes,
              image.width,
              image.height,
              uvRowStride,
              uvPixelStride,
              cropBb,
              ageSz,
              ageSz,
              mode: NormalizationMode.standard,
            );

            final genSz = _tfliteService.genderInputSize;
            final genderInput = yuvToRgbInput(
              image.planes[0].bytes,
              uBytes,
              vBytes,
              image.width,
              image.height,
              uvRowStride,
              uvPixelStride,
              cropBb,
              genSz,
              genSz,
              mode: NormalizationMode.standard,
            );

            Float32List? ethInput;
            if (_tfliteService.hasEthnicity) {
              final ethSz = _tfliteService.ethnicityInputSize;
              ethInput = yuvToRgbInput(
                image.planes[0].bytes,
                uBytes,
                vBytes,
                image.width,
                image.height,
                uvRowStride,
                uvPixelStride,
                cropBb,
                ethSz,
                ethSz,
                mode: NormalizationMode.standard,
              );
            }

            final attrs = await _tfliteService.predictAttributes(
              ageInput,
              genderInput,
              faceRgbEthnicity: ethInput,
            );

            // Per-face attribute smoothing
            _ageHistoryMap.putIfAbsent(trackingId, () => []);
            _genderHistoryMap.putIfAbsent(trackingId, () => []);
            _ethnicityHistoryMap.putIfAbsent(trackingId, () => []);

            _ageHistoryMap[trackingId]!.add(attrs.age);
            _genderHistoryMap[trackingId]!.add(attrs.gender);
            if (attrs.ethnicity != 'Unknown') {
              _ethnicityHistoryMap[trackingId]!.add(attrs.ethnicity);
            }
            if (_ageHistoryMap[trackingId]!.length > attributeHistoryLength) {
              _ageHistoryMap[trackingId]!.removeAt(0);
            }
            if (_genderHistoryMap[trackingId]!.length >
                attributeHistoryLength) {
              _genderHistoryMap[trackingId]!.removeAt(0);
            }
            if (_ethnicityHistoryMap[trackingId]!.length >
                attributeHistoryLength) {
              _ethnicityHistoryMap[trackingId]!.removeAt(0);
            }

            gender = _getSmoothedGenderFor(trackingId);
            ageRange = '~${_getSmoothedAgeFor(trackingId)}';
            ethnicity = _getSmoothedEthnicityFor(trackingId);
          } catch (e) {
            debugPrint('[FaceProvider] Attribute prediction error: $e');
          }
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
          rawSmileProb: face.smilingProbability,
          leftEyeOpenProb: face.leftEyeOpenProbability,
          rightEyeOpenProb: face.rightEyeOpenProbability,
          headEulerAngleX: face.headEulerAngleX,
          headEulerAngleY: face.headEulerAngleY,
          headEulerAngleZ: face.headEulerAngleZ,
          trackingId: trackingId,
        ));

        // Emotion alert check
        if (_alertEmotion != null &&
            smoothedEmotion == _alertEmotion &&
            smoothed >= _alertThreshold) {
          onEmotionAlert?.call(smoothedEmotion, smoothed, fi);
        }
      }

      // Cleanup stale tracking data
      if (facesToProcess.isEmpty) {
        _expressionHistoryMap.clear();
        _ageHistoryMap.clear();
        _genderHistoryMap.clear();
        _ethnicityHistoryMap.clear();
      } else {
        _expressionHistoryMap
            .removeWhere((k, _) => !activeTrackingIds.contains(k));
        _ageHistoryMap.removeWhere((k, _) => !activeTrackingIds.contains(k));
        _genderHistoryMap.removeWhere((k, _) => !activeTrackingIds.contains(k));
        _ethnicityHistoryMap
            .removeWhere((k, _) => !activeTrackingIds.contains(k));
      }

      // Update FPS tracking
      _fpsFrameCount++;
      final now = DateTime.now();
      final elapsed = now.difference(_fpsLastTime).inMilliseconds;
      if (elapsed > 1000) {
        _currentFps = _fpsFrameCount * 1000.0 / elapsed;
        _fpsFrameCount = 0;
        _fpsLastTime = now;
      }

      final changedCount = _faces.length != _lastFaceCount;
      _lastFaceCount = _faces.length;

      _notifyThrottle = (_notifyThrottle + 1) % 2;
      if (_notifyThrottle == 0 || changedCount) {
        notifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint('[FaceProvider] Frame error: $e');
      debugPrint('[FaceProvider] Stack trace: $stackTrace');
    } finally {
      _frameStopwatch.stop();
      _lastLatencyMs = _frameStopwatch.elapsedMilliseconds.toDouble();
      _busy = false;
    }
  }

  Emotion _getSmoothedEmotionFor(int trackingId) {
    final history = _expressionHistoryMap[trackingId];
    if (history == null || history.isEmpty) return Emotion.neutral;
    final counts = <Emotion, int>{};
    for (var emotion in history) {
      counts[emotion] = (counts[emotion] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  int _getSmoothedAgeFor(int trackingId) {
    final history = _ageHistoryMap[trackingId];
    if (history == null || history.isEmpty) return 0;
    final sorted = List<int>.from(history)..sort();
    return sorted[sorted.length ~/ 2];
  }

  String _getSmoothedGenderFor(int trackingId) {
    final history = _genderHistoryMap[trackingId];
    if (history == null || history.isEmpty) return 'Unknown';
    final counts = <String, int>{};
    for (var gender in history) {
      counts[gender] = (counts[gender] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String _getSmoothedEthnicityFor(int trackingId) {
    final history = _ethnicityHistoryMap[trackingId];
    if (history == null || history.isEmpty) return 'Unknown';
    final counts = <String, int>{};
    for (var eth in history) {
      counts[eth] = (counts[eth] ?? 0) + 1;
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
