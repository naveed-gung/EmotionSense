import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class UnifiedTFLiteService {
  Interpreter? _ageModel;
  Interpreter? _genderModel;

  bool _isInitialized = false;
  bool _attributesAvailable =
      false; // Track if age/gender models loaded successfully

  bool get isInitialized => _isInitialized; // Face detection initialized
  bool get hasAttributes => _attributesAvailable; // Age/Gender models available

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load separate age and gender models (face detection handled by ML Kit)
      try {
        debugPrint('[TFLite] Loading age model: model_lite_age_q.tflite...');
        _ageModel = await Interpreter.fromAsset(
          'assets/models/model_lite_age_q.tflite',
          options: InterpreterOptions()..threads = 2,
        );
        debugPrint(
            '[TFLite] Age model loaded. Input: ${_ageModel!.getInputTensors()[0].shape}, Output: ${_ageModel!.getOutputTensors()[0].shape}');

        debugPrint(
            '[TFLite] Loading gender model: model_lite_gender_q.tflite...');
        _genderModel = await Interpreter.fromAsset(
          'assets/models/model_lite_gender_q.tflite',
          options: InterpreterOptions()..threads = 2,
        );
        debugPrint(
            '[TFLite] Gender model loaded. Input: ${_genderModel!.getInputTensors()[0].shape}, Output: ${_genderModel!.getOutputTensors()[0].shape}');

        _attributesAvailable = true;
        debugPrint('[TFLite] ✅ Age/Gender models loaded successfully');
      } catch (e) {
        debugPrint('[TFLite] ⚠️ Failed to load age/gender models: $e');
        debugPrint('[TFLite] ℹ️ Age/Gender will show as "Unknown"');
        _attributesAvailable = false;
        _ageModel = null;
        _genderModel = null;
      }

      _isInitialized = true;
      debugPrint(
          '[TFLite] Initialization complete (age/gender models: $_attributesAvailable)');
    } catch (e, st) {
      debugPrint('[TFLite] init error: $e');
      debugPrint('[TFLite] Stack trace: $st');
      rethrow;
    }
  }

  Future<Attributes> predictAttributes(
      Float32List faceRgb200, Float32List faceRgb128) async {
    if (!_isInitialized ||
        !_attributesAvailable ||
        _ageModel == null ||
        _genderModel == null) {
      throw StateError('Age/Gender models not available');
    }

    // Age model: expects [1, 200, 200, 3]
    final ageInputShape = _ageModel!.getInputTensors()[0].shape;
    final ageOutput =
        List.filled(_ageModel!.getOutputTensors()[0].numElements(), 0.0)
            .reshape(_ageModel!.getOutputTensors()[0].shape);

    _ageModel!.run(faceRgb200.reshape(ageInputShape), ageOutput);

    // Gender model: expects [1, 128, 128, 3]
    final genderInputShape = _genderModel!.getInputTensors()[0].shape;
    final genderOutput =
        List.filled(_genderModel!.getOutputTensors()[0].numElements(), 0.0)
            .reshape(_genderModel!.getOutputTensors()[0].shape);

    _genderModel!.run(faceRgb128.reshape(genderInputShape), genderOutput);

    final age = _parseAge(ageOutput);
    final gender = _parseGender(genderOutput);

    debugPrint('[TFLite] Predicted Age: $age, Gender: $gender');

    return Attributes(
      age: age,
      gender: gender,
      ethnicity: 'Unknown', // No ethnicity model
      emotion: 'Neutral', // Emotion from ML Kit
    );
  }

  int _parseAge(List ageOut) {
    final flat = ageOut is List<List> ? ageOut[0] : ageOut;
    final rawValue = flat[0] as double;

    // Debug: print raw model output
    debugPrint('[TFLite] Raw age output: $rawValue');

    // Tuning parameters - adjust these based on your needs
    const double ageMultiplier = 116.0; // Model trained on 0-116 age range
    const double ageOffset = 0.0; // Add offset if ages are consistently off
    const double ageScale = 1.0; // Scale adjustment (increase if ages too low)

    // Apply calibration: (raw * multiplier * scale) + offset
    final calibratedAge =
        ((rawValue * ageMultiplier * ageScale) + ageOffset).round();

    debugPrint(
        '[TFLite] Calibrated age: $calibratedAge (raw: $rawValue × $ageMultiplier × $ageScale + $ageOffset)');

    return calibratedAge.clamp(0, 120);
  }

  String _parseGender(List genderOut) {
    final flat = genderOut is List<List> ? genderOut[0] : genderOut;

    // Output is [male_prob, female_prob]
    final maleProb = flat[0] as double;
    final femaleProb = flat.length > 1 ? flat[1] as double : (1.0 - maleProb);

    // Tuning: adjust confidence threshold (default 0.5)
    const double genderThreshold =
        0.5; // Higher = more confident needed for male
    const double confidenceBoost = 0.0; // Adjust if gender detection biased

    final adjustedMaleProb = (maleProb + confidenceBoost).clamp(0.0, 1.0);

    debugPrint(
        '[TFLite] Gender probs: Male=$maleProb, Female=$femaleProb (adjusted male: $adjustedMaleProb, threshold: $genderThreshold)');

    return adjustedMaleProb > genderThreshold ? 'Male' : 'Female';
  }

  void dispose() {
    _ageModel?.close();
    _genderModel?.close();
    _isInitialized = false;
    _attributesAvailable = false;
  }
}

class Attributes {
  final int age;
  final String gender;
  final String ethnicity;
  final String emotion;

  Attributes({
    required this.age,
    required this.gender,
    required this.ethnicity,
    required this.emotion,
  });
}
