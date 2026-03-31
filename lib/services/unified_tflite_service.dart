import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class UnifiedTFLiteService {
  Interpreter? _ageModel;
  Interpreter? _genderModel;
  Interpreter? _ethnicityModel;

  bool _isInitialized = false;
  bool _attributesAvailable = false;
  bool _ethnicityAvailable = false;

  // Performance mode: 'accuracy' (2 threads) or 'speed' (4 threads, GPU delegate)
  String _performanceMode = 'accuracy';
  int get _threads => _performanceMode == 'speed' ? 4 : 2;

  // Model metadata discovered at init
  List<int> _ageInputShape = [];
  List<int> _genderInputShape = [];
  List<int> _ethnicityInputShape = [];

  bool get isInitialized => _isInitialized;
  bool get hasAttributes => _attributesAvailable;
  bool get hasEthnicity => _ethnicityAvailable;

  /// Get the required input size for age model (width = height)
  int get ageInputSize => _ageInputShape.length >= 3 ? _ageInputShape[1] : 200;

  /// Get the required input size for gender model
  int get genderInputSize =>
      _genderInputShape.length >= 3 ? _genderInputShape[1] : 128;

  /// Get the required input size for ethnicity model
  int get ethnicityInputSize =>
      _ethnicityInputShape.length >= 3 ? _ethnicityInputShape[1] : 200;

  static const List<String> ethnicityLabels = [
    'White',
    'Black',
    'Asian',
    'Indian',
    'Other',
  ];

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load age model
      try {
        debugPrint('[TFLite] Loading age model...');
        _ageModel = await Interpreter.fromAsset(
          'assets/models/model_lite_age_q.tflite',
          options: InterpreterOptions()..threads = _threads,
        );
        _ageInputShape = _ageModel!.getInputTensors()[0].shape;
        final ageOutShape = _ageModel!.getOutputTensors()[0].shape;
        final ageOutType = _ageModel!.getOutputTensors()[0].type;
        debugPrint(
            '[TFLite] Age model: input=$_ageInputShape, output=$ageOutShape, type=$ageOutType');

        debugPrint('[TFLite] Loading gender model...');
        _genderModel = await Interpreter.fromAsset(
          'assets/models/model_lite_gender_q.tflite',
          options: InterpreterOptions()..threads = _threads,
        );
        _genderInputShape = _genderModel!.getInputTensors()[0].shape;
        final genderOutShape = _genderModel!.getOutputTensors()[0].shape;
        final genderOutType = _genderModel!.getOutputTensors()[0].type;
        debugPrint(
            '[TFLite] Gender model: input=$_genderInputShape, output=$genderOutShape, type=$genderOutType');

        _attributesAvailable = true;
        debugPrint('[TFLite] Age/Gender models loaded successfully');
      } catch (e) {
        debugPrint('[TFLite] Failed to load age/gender models: $e');
        _attributesAvailable = false;
        _ageModel = null;
        _genderModel = null;
      }

      // Load ethnicity model
      try {
        debugPrint('[TFLite] Loading ethnicity model...');
        _ethnicityModel = await Interpreter.fromAsset(
          'assets/models/age_gender_ethnicity_new.tflite',
          options: InterpreterOptions()..threads = _threads,
        );
        _ethnicityInputShape = _ethnicityModel!.getInputTensors()[0].shape;
        final ethOutShape = _ethnicityModel!.getOutputTensors()[0].shape;
        final ethOutType = _ethnicityModel!.getOutputTensors()[0].type;
        debugPrint(
            '[TFLite] Ethnicity model: input=$_ethnicityInputShape, output=$ethOutShape, type=$ethOutType');
        _ethnicityAvailable = true;
        debugPrint('[TFLite] Ethnicity model loaded successfully');
      } catch (e) {
        debugPrint('[TFLite] Ethnicity model not available: $e');
        _ethnicityAvailable = false;
        _ethnicityModel = null;
      }

      _isInitialized = true;
      debugPrint(
          '[TFLite] Init complete: age/gender=$_attributesAvailable, ethnicity=$_ethnicityAvailable');
    } catch (e, st) {
      debugPrint('[TFLite] init error: $e');
      debugPrint('[TFLite] Stack trace: $st');
      rethrow;
    }
  }

  Future<Attributes> predictAttributes(
    Float32List faceRgbAge,
    Float32List faceRgbGender, {
    Float32List? faceRgbEthnicity,
  }) async {
    if (!_isInitialized || !_attributesAvailable) {
      throw StateError('Age/Gender models not available');
    }

    // Age model
    final ageOutput =
        List.filled(_ageModel!.getOutputTensors()[0].numElements(), 0.0)
            .reshape(_ageModel!.getOutputTensors()[0].shape);
    _ageModel!.run(faceRgbAge.reshape(_ageInputShape), ageOutput);

    // Gender model
    final genderOutput =
        List.filled(_genderModel!.getOutputTensors()[0].numElements(), 0.0)
            .reshape(_genderModel!.getOutputTensors()[0].shape);
    _genderModel!.run(faceRgbGender.reshape(_genderInputShape), genderOutput);

    final age = _parseAge(ageOutput);
    final gender = _parseGender(genderOutput);

    // Ethnicity model (optional)
    String ethnicity = 'Unknown';
    if (_ethnicityAvailable &&
        _ethnicityModel != null &&
        faceRgbEthnicity != null) {
      try {
        ethnicity = await _predictEthnicity(faceRgbEthnicity);
      } catch (e) {
        debugPrint('[TFLite] Ethnicity prediction error: $e');
      }
    }

    debugPrint('[TFLite] Predicted Age=$age, Gender=$gender, Eth=$ethnicity');

    return Attributes(
      age: age,
      gender: gender,
      ethnicity: ethnicity,
      emotion: 'Neutral',
    );
  }

  Future<String> _predictEthnicity(Float32List faceRgb) async {
    final outTensor = _ethnicityModel!.getOutputTensors()[0];
    final numOutputs = outTensor.numElements();
    final output = List.filled(numOutputs, 0.0).reshape(outTensor.shape);

    _ethnicityModel!.run(faceRgb.reshape(_ethnicityInputShape), output);

    final flat = output is List<List> ? output[0] : output;

    // The ethnicity model may output:
    // - Multiple outputs including age, gender, ethnicity (common for combined models)
    // - Just ethnicity probabilities

    // If the output has more elements than ethnicity labels, it may be a combined model.
    // For a combined age/gender/ethnicity model (common pattern):
    // Output shape is typically [1, N] where N could be:
    //   - N=1 (single regression) or
    //   - N=5 (5 ethnicity classes) or
    //   - N=7+ (age + gender + 5 ethnicity)

    if (numOutputs >= 5) {
      // If combined model: last 5 outputs are ethnicity
      // If pure ethnicity model: all 5 outputs are ethnicity
      int startIdx = 0;
      if (numOutputs > 5) {
        // Combined model: skip age (1) + gender (1 or 2)
        startIdx = numOutputs - 5;
      }

      double maxProb = -1;
      int maxIdx = 0;
      for (int i = 0; i < 5; i++) {
        final prob = (flat[startIdx + i] as num).toDouble();
        if (prob > maxProb) {
          maxProb = prob;
          maxIdx = i;
        }
      }

      if (maxIdx < ethnicityLabels.length) {
        debugPrint(
            '[TFLite] Ethnicity probs: ${List.generate(5, (i) => '${ethnicityLabels[i]}=${(flat[startIdx + i] as num).toStringAsFixed(3)}')}');
        return ethnicityLabels[maxIdx];
      }
    } else if (numOutputs == 1) {
      // Single regression output — round to class index
      final idx = (flat[0] as num).round().clamp(0, ethnicityLabels.length - 1);
      return ethnicityLabels[idx];
    }

    return 'Unknown';
  }

  int _parseAge(List ageOut) {
    final flat = ageOut is List<List> ? ageOut[0] : ageOut;
    final rawValue = (flat[0] as num).toDouble();

    debugPrint('[TFLite] Raw age output: $rawValue');

    // Auto-detect scaling:
    // If raw value > 1.0, model outputs direct age (no multiplier needed)
    // If raw value is in [0, 1], it's a normalized output → multiply by age range
    int age;
    if (rawValue > 1.5) {
      // Direct age output
      age = rawValue.round();
      debugPrint('[TFLite] Age direct: $age');
    } else if (rawValue >= 0.0 && rawValue <= 1.0) {
      // Normalized [0, 1] → scale by typical age range
      age = (rawValue * 100.0).round();
      debugPrint('[TFLite] Age from normalized: $age (raw * 100)');
    } else if (rawValue < 0) {
      // Negative — might be MobileNet-normalized output
      age = ((rawValue + 1.0) * 50.0).round();
      debugPrint('[TFLite] Age from negative: $age');
    } else {
      age = rawValue.round();
    }

    return age.clamp(1, 120);
  }

  String _parseGender(List genderOut) {
    final flat = genderOut is List<List> ? genderOut[0] : genderOut;
    final numOutputs = flat.length;

    debugPrint('[TFLite] Gender output ($numOutputs values): $flat');

    if (numOutputs >= 2) {
      final prob0 = (flat[0] as num).toDouble();
      final prob1 = (flat[1] as num).toDouble();

      // FIXED: Standard convention for most face-attribute models
      // (UTKFace, FairFace, face-attributes-pytorch):
      //   Index 0 = Female probability
      //   Index 1 = Male probability
      debugPrint('[TFLite] Gender probs: Female=$prob0, Male=$prob1');

      return prob1 > prob0 ? 'Male' : 'Female';
    } else {
      // Single output: typically sigmoid
      // > 0.5 = Male, <= 0.5 = Female (or vice versa)
      final prob = (flat[0] as num).toDouble();
      debugPrint('[TFLite] Gender single output: $prob');
      // For most models: higher = male
      return prob > 0.5 ? 'Male' : 'Female';
    }
  }

  void dispose() {
    _ageModel?.close();
    _genderModel?.close();
    _ethnicityModel?.close();
    _isInitialized = false;
    _attributesAvailable = false;
    _ethnicityAvailable = false;
  }

  String get performanceMode => _performanceMode;

  /// Hot-swap performance mode: reinitializes models with new thread count.
  Future<void> setPerformanceMode(String mode) async {
    if (mode == _performanceMode) return;
    _performanceMode = mode;
    debugPrint('[TFLite] Switching to $mode mode (threads=$_threads)');
    // Reinitialize models with new thread count
    dispose();
    await initialize();
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
