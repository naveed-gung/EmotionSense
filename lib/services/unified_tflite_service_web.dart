import 'dart:typed_data';

class UnifiedTFLiteService {
  bool get isInitialized => true;
  bool get hasAttributes => false;
  bool get hasEthnicity => false;
  int get ageInputSize => 200;
  int get genderInputSize => 128;
  int get ethnicityInputSize => 200;
  String get performanceMode => 'web';

  static const List<String> ethnicityLabels = [
    'White',
    'Black',
    'Asian',
    'Indian',
    'Other',
  ];

  Future<void> initialize() async {}

  Future<Attributes> predictAttributes(
    Float32List faceRgbAge,
    Float32List faceRgbGender, {
    Float32List? faceRgbEthnicity,
  }) async {
    return Attributes(
      age: 25,
      gender: 'Unknown',
      ethnicity: 'Unknown',
      emotion: 'Neutral',
    );
  }

  Future<void> setPerformanceMode(String mode) async {}

  void dispose() {}
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