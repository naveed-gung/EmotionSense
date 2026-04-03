import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

List<double> _flatten(dynamic raw) {
  final out = <double>[];

  void walk(dynamic value) {
    if (value is List) {
      for (final entry in value) {
        walk(entry);
      }
      return;
    }
    out.add((value as num).toDouble());
  }

  walk(raw);
  return out;
}

class UnifiedTFLiteService {
  Interpreter? _ageModel;
  Interpreter? _genderModel;
  Interpreter? _ethnicityModel;

  bool _isInitialized = false;
  bool _attributesAvailable = false;
  bool _ethnicityAvailable = false;

  String _performanceMode = 'accuracy';
  int get _threads => _performanceMode == 'speed' ? 4 : 2;

  List<int> _ageInputShape = [];
  List<int> _genderInputShape = [];
  List<int> _ethnicityInputShape = [];

  bool get isInitialized => _isInitialized;
  bool get hasAttributes => _attributesAvailable;
  bool get hasEthnicity => _ethnicityAvailable;

  int get ageInputSize => _ageInputShape.length >= 3 ? _ageInputShape[1] : 200;
  int get genderInputSize =>
      _genderInputShape.length >= 3 ? _genderInputShape[1] : 128;
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

    final ageOutput =
        List.filled(_ageModel!.getOutputTensors()[0].numElements(), 0.0)
            .reshape(_ageModel!.getOutputTensors()[0].shape);
    _ageModel!.run(faceRgbAge.reshape(_ageInputShape), ageOutput);

    final genderOutput =
        List.filled(_genderModel!.getOutputTensors()[0].numElements(), 0.0)
            .reshape(_genderModel!.getOutputTensors()[0].shape);
    _genderModel!.run(faceRgbGender.reshape(_genderInputShape), genderOutput);

    final age = _parseAge(ageOutput);
    final (genderLabel, genderConf) = _parseGender(genderOutput);

    String ethnicity = 'Unknown';
    double ethnicityConf = 0.0;
    if (_ethnicityAvailable &&
        _ethnicityModel != null &&
        faceRgbEthnicity != null) {
      try {
        (ethnicity, ethnicityConf) = await _predictEthnicity(faceRgbEthnicity);
      } catch (e) {
        debugPrint('[TFLite] Ethnicity prediction error: $e');
      }
    }

    debugPrint(
      '[TFLite] age=$age gender=$genderLabel(${genderConf.toStringAsFixed(2)}) '
      'eth=$ethnicity(${ethnicityConf.toStringAsFixed(2)})',
    );

    return Attributes(
      age: age,
      gender: genderLabel,
      genderConf: genderConf,
      ethnicity: ethnicity,
      ethnicityConf: ethnicityConf,
    );
  }

  Future<(String, double)> _predictEthnicity(Float32List faceRgb) async {
    final outTensor = _ethnicityModel!.getOutputTensors()[0];
    final numOutputs = outTensor.numElements();
    final output = List.filled(numOutputs, 0.0).reshape(outTensor.shape);

    _ethnicityModel!.run(faceRgb.reshape(_ethnicityInputShape), output);

    final flat = _flatten(output);
    debugPrint('[TFLite] ethnicity raw (${flat.length} vals): $flat');

    if (flat.isEmpty) {
      return ('Unknown', 0.0);
    }

    if (flat.length == 1) {
      final idx = flat[0].round().clamp(0, ethnicityLabels.length - 1);
      return (ethnicityLabels[idx], 0.7);
    }

    final startIdx = math.max(flat.length - 5, 0);
    final probs = flat.sublist(startIdx);
    final sum = probs.fold<double>(0.0, (acc, value) => acc + value);

    List<double> normalized;
    if (sum < 0.05) {
      final maxLogit = probs.reduce(math.max);
      final exps = probs.map((value) => math.exp(value - maxLogit)).toList();
      final expSum = exps.fold<double>(0.0, (acc, value) => acc + value);
      normalized = expSum > 0
          ? exps.map((value) => value / expSum).toList()
          : List<double>.from(probs);
    } else {
      normalized = sum > 1.5
          ? probs.map((value) => value / sum).toList()
          : List<double>.from(probs);
    }

    var maxProb = 0.0;
    var maxIdx = 0;
    for (var index = 0;
        index < normalized.length && index < ethnicityLabels.length;
        index++) {
      if (normalized[index] > maxProb) {
        maxProb = normalized[index];
        maxIdx = index;
      }
    }

    debugPrint(
      '[TFLite] ethnicity -> ${ethnicityLabels[maxIdx]} '
      '(${maxProb.toStringAsFixed(3)})',
    );
    return (ethnicityLabels[maxIdx], maxProb.clamp(0.0, 1.0));
  }

  int _parseAge(List ageOut) {
    final flat = _flatten(ageOut);
    if (flat.isEmpty) {
      return 25;
    }

    final raw = flat[0];
    debugPrint('[TFLite] age raw: $raw');

    int age;
    if (raw > 1.5) {
      age = raw.round();
    } else if (raw >= 0.0 && raw <= 1.0) {
      age = (raw * 116).round();
    } else {
      age = ((raw + 1.0) * 58).round();
    }

    age = age.clamp(1, 100);
    debugPrint('[TFLite] age parsed: $age');
    return age;
  }

  (String, double) _parseGender(List genderOut) {
    final flat = _flatten(genderOut);
    debugPrint('[TFLite] gender raw: $flat');
    if (flat.isEmpty) {
      return ('Unknown', 0.0);
    }

    if (flat.length >= 2) {
      final rawA = flat[0];
      final rawB = flat[1];
      List<double> normalized;

      final sum = rawA + rawB;
      if (rawA < 0 || rawB < 0 || sum > 1.5) {
        final maxLogit = math.max(rawA, rawB);
        final expA = math.exp(rawA - maxLogit);
        final expB = math.exp(rawB - maxLogit);
        final expSum = expA + expB;
        normalized = [expA / expSum, expB / expSum];
      } else if (sum > 0) {
        normalized = [rawA / sum, rawB / sum];
      } else {
        normalized = [0.5, 0.5];
      }

      // This model family uses male-first ordering.
      final maleProb = normalized[0].clamp(0.0, 1.0);
      final femaleProb = normalized[1].clamp(0.0, 1.0);
      final confidence = math.max(maleProb, femaleProb);
      final margin = (maleProb - femaleProb).abs();

      if (margin < 0.12) {
        return ('Unknown', confidence);
      }

      return maleProb >= femaleProb
          ? ('Male', confidence)
          : ('Female', confidence);
    }

    final femaleProb = flat[0].clamp(0.0, 1.0);
    final maleProb = (1 - femaleProb).clamp(0.0, 1.0);
    final confidence = math.max(maleProb, femaleProb);
    final margin = (maleProb - femaleProb).abs();

    if (margin < 0.12) {
      return ('Unknown', confidence);
    }

    return maleProb >= femaleProb
        ? ('Male', confidence)
        : ('Female', confidence);
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

  Future<void> setPerformanceMode(String mode) async {
    if (mode == _performanceMode) return;
    _performanceMode = mode;
    debugPrint('[TFLite] Switching to $mode mode (threads=$_threads)');
    dispose();
    await initialize();
  }
}

class Attributes {
  final int age;
  final String gender;
  final double genderConf;
  final String ethnicity;
  final double ethnicityConf;

  const Attributes({
    required this.age,
    required this.gender,
    this.genderConf = 0.0,
    required this.ethnicity,
    this.ethnicityConf = 0.0,
  });

  String get ageRange {
    if (age < 13) return 'Under 13';
    if (age < 18) return '13-17';
    if (age < 25) return '18-24';
    if (age < 35) return '25-34';
    if (age < 45) return '35-44';
    if (age < 55) return '45-54';
    if (age < 65) return '55-64';
    return '65+';
  }
}
