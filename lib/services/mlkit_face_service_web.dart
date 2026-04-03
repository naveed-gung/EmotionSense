import 'dart:ui';

class MLKitFaceService {
  bool get isInitialized => false;
  dynamic get faceDetector => null;

  double smileThresholdHappy = 0.70;
  double smileThresholdSad = 0.15;
  double frownYDifference = 8.0;

  void updateThresholds({
    double? happy,
    double? sad,
    double? frownY,
  }) {}

  Future<void> initialize() async {}

  Future<List<MLKitFace>> detectFaces(dynamic image, dynamic camera) async =>
      [];

  String inferEmotion(
    double? smilingProbability,
    double? leftEyeOpen,
    double? rightEyeOpen,
    dynamic face,
  ) =>
      'Neutral';

  static double getEmotionConfidence(double? smilingProbability) {
    if (smilingProbability == null) return 0.5;
    if (smilingProbability > 0.8 || smilingProbability < 0.1) return 0.9;
    if (smilingProbability > 0.5 || smilingProbability < 0.3) return 0.7;
    return 0.5;
  }

  void dispose() {}
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
