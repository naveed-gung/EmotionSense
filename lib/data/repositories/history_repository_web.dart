import 'dart:convert';

import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/data/models/age_gender_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryEntry {
  HistoryEntry({
    required this.imagePath,
    required this.emotion,
    required this.confidence,
    required this.timestamp,
    this.ageGender,
  });

  final String imagePath;
  final Emotion emotion;
  final double confidence;
  final DateTime timestamp;
  final AgeGenderData? ageGender;

  Map<String, dynamic> toJson() => {
        'imagePath': imagePath,
        'emotion': emotion.name,
        'confidence': confidence,
        'timestamp': timestamp.toIso8601String(),
        'ageRange': ageGender?.ageRange,
        'gender': ageGender?.gender,
        'ageGenderConfidence': ageGender?.confidence,
      };

  static HistoryEntry fromJson(Map<String, dynamic> json) => HistoryEntry(
        imagePath: json['imagePath'] as String,
        emotion: Emotion.values.firstWhere(
          (e) => e.name == (json['emotion'] as String? ?? 'neutral'),
          orElse: () => Emotion.neutral,
        ),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        ageGender: (json['ageRange'] == null || json['gender'] == null)
            ? null
            : AgeGenderData(
                ageRange: json['ageRange'] as String? ?? 'Unknown',
                gender: json['gender'] as String? ?? 'Unknown',
                confidence:
                    (json['ageGenderConfidence'] as num?)?.toDouble() ?? 0.0,
              ),
      );
}

class HistoryRepository {
  static const _storageKey = 'emotion_sense_history';

  Future<List<HistoryEntry>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final text = prefs.getString(_storageKey);
      if (text == null || text.isEmpty) return [];
      final list =
          (jsonDecode(text) as List<dynamic>).cast<Map<String, dynamic>>();
      return list.map(HistoryEntry.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<HistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  Future<String> persistImage(String tempPath) async => tempPath;

  Future<void> deleteImageAtPath(String path) async {}
}
