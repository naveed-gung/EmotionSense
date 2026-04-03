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
    return const Attributes(
      age: 0,
      gender: 'Unknown',
      ethnicity: 'Unknown',
    );
  }

  Future<void> setPerformanceMode(String mode) async {}

  void dispose() {}
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
