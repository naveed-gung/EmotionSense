import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _kShowAgeGender = 'show_age_gender';
  static const _kSoundOn = 'sound_on';
  static const _kHapticOn = 'haptic_on';
  static const _kThemeMode = 'theme_mode'; // system, light, dark
  static const _kSensitivity = 'detection_sensitivity';
  static const _kFrameRate = 'frame_rate';
  static const _kAutoCapture = 'auto_capture_enabled';
  static const _kSmoothAlpha = 'smoothing_alpha';
  static const _kConfWindow = 'confidence_window';
  static const _kMissingNeutral = 'missing_frames_neutral';
  static const _kAutoConf = 'auto_capture_confidence';
  static const _kAutoCooldown = 'auto_capture_cooldown_sec';
  static const _kMouthOpenTh = 'mouth_open_threshold';
  static const _kBrowCompTh = 'brow_compression_threshold';
  static const _kEnergyTh = 'energy_threshold';
  static const _kTargetFps = 'target_fps';
  static const _kSmileTh = 'smile_threshold';
  static const _kEyeOpenTh = 'eye_open_threshold';
  static const _kEthnicityEnabled = 'ethnicity_enabled';
  static const _kHasSeenOnboarding = 'has_seen_onboarding';
  static const _kModelMode = 'model_mode'; // 'accuracy' or 'speed'
  static const _kAlertEmotion = 'alert_emotion'; // emotion name or empty
  static const _kAlertThreshold = 'alert_threshold'; // 0.0..1.0
  static const _kEmojiRainEnabled = 'emoji_rain_enabled';
  static const _kFastEmotionResponse = 'fast_emotion_response';

  Future<bool> getShowAgeGender() async =>
      (await SharedPreferences.getInstance()).getBool(_kShowAgeGender) ?? true;
  Future<void> setShowAgeGender(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_kShowAgeGender, v);

  Future<bool> getSoundOn() async =>
      (await SharedPreferences.getInstance()).getBool(_kSoundOn) ?? true;
  Future<void> setSoundOn(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_kSoundOn, v);

  Future<bool> getHapticOn() async =>
      (await SharedPreferences.getInstance()).getBool(_kHapticOn) ?? true;
  Future<void> setHapticOn(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_kHapticOn, v);

  Future<ThemeMode> getThemeMode() async {
    final s = (await SharedPreferences.getInstance()).getString(_kThemeMode);
    return switch (s) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final s = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    (await SharedPreferences.getInstance()).setString(_kThemeMode, s);
  }

  Future<double> getSensitivity() async =>
      (await SharedPreferences.getInstance()).getDouble(_kSensitivity) ?? 0.6;
  Future<void> setSensitivity(double v) async =>
      (await SharedPreferences.getInstance()).setDouble(_kSensitivity, v);

  Future<int> getFrameRate() async =>
      (await SharedPreferences.getInstance()).getInt(_kFrameRate) ?? 15;
  Future<void> setFrameRate(int v) async =>
      (await SharedPreferences.getInstance()).setInt(_kFrameRate, v);

  // New advanced settings
  Future<bool> getAutoCapture() async =>
      (await SharedPreferences.getInstance()).getBool(_kAutoCapture) ?? true;
  Future<void> setAutoCapture(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_kAutoCapture, v);

  Future<double> getSmoothingAlpha() async =>
      (await SharedPreferences.getInstance()).getDouble(_kSmoothAlpha) ?? 0.4;
  Future<void> setSmoothingAlpha(double v) async =>
      (await SharedPreferences.getInstance()).setDouble(_kSmoothAlpha, v);

  Future<int> getConfidenceWindow() async =>
      (await SharedPreferences.getInstance()).getInt(_kConfWindow) ?? 12;
  Future<void> setConfidenceWindow(int v) async =>
      (await SharedPreferences.getInstance()).setInt(_kConfWindow, v);

  Future<int> getMissingFramesNeutral() async =>
      (await SharedPreferences.getInstance()).getInt(_kMissingNeutral) ?? 45;
  Future<void> setMissingFramesNeutral(int v) async =>
      (await SharedPreferences.getInstance()).setInt(_kMissingNeutral, v);

  Future<double> getAutoCaptureConfidence() async =>
      (await SharedPreferences.getInstance()).getDouble(_kAutoConf) ?? 0.75;
  Future<void> setAutoCaptureConfidence(double v) async =>
      (await SharedPreferences.getInstance()).setDouble(_kAutoConf, v);

  Future<int> getAutoCaptureCooldownSec() async =>
      (await SharedPreferences.getInstance()).getInt(_kAutoCooldown) ?? 8;
  Future<void> setAutoCaptureCooldownSec(int v) async =>
      (await SharedPreferences.getInstance()).setInt(_kAutoCooldown, v);

  // Thresholds
  Future<double> getMouthOpenThreshold() async =>
      (await SharedPreferences.getInstance()).getDouble(_kMouthOpenTh) ?? 0.18;
  Future<void> setMouthOpenThreshold(double v) async =>
      (await SharedPreferences.getInstance()).setDouble(_kMouthOpenTh, v);

  Future<double> getBrowCompressionThreshold() async =>
      (await SharedPreferences.getInstance()).getDouble(_kBrowCompTh) ?? 0.10;
  Future<void> setBrowCompressionThreshold(double v) async =>
      (await SharedPreferences.getInstance()).setDouble(_kBrowCompTh, v);

  Future<double> getEnergyThreshold() async =>
      (await SharedPreferences.getInstance()).getDouble(_kEnergyTh) ?? 0.25;
  Future<void> setEnergyThreshold(double v) async =>
      (await SharedPreferences.getInstance()).setDouble(_kEnergyTh, v);

  // Target FPS (analysis)
  Future<int> getTargetFps() async =>
      (await SharedPreferences.getInstance()).getInt(_kTargetFps) ?? 15;
  Future<void> setTargetFps(int v) async =>
      (await SharedPreferences.getInstance()).setInt(_kTargetFps, v);

  Future<double> getSmileThreshold() async =>
      (await SharedPreferences.getInstance()).getDouble(_kSmileTh) ?? 0.50;
  Future<void> setSmileThreshold(double v) async =>
      (await SharedPreferences.getInstance()).setDouble(_kSmileTh, v);

  Future<double> getEyeOpenThreshold() async =>
      (await SharedPreferences.getInstance()).getDouble(_kEyeOpenTh) ?? 0.45;
  Future<void> setEyeOpenThreshold(double v) async =>
      (await SharedPreferences.getInstance()).setDouble(_kEyeOpenTh, v);

  Future<bool> getEthnicityEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_kEthnicityEnabled) ??
      true; // Enabled by default
  Future<void> setEthnicityEnabled(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_kEthnicityEnabled, v);

  // Onboarding
  Future<bool> getHasSeenOnboarding() async =>
      (await SharedPreferences.getInstance()).getBool(_kHasSeenOnboarding) ??
      false;
  Future<void> setHasSeenOnboarding(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_kHasSeenOnboarding, v);

  // Model mode (accuracy vs speed)
  Future<String> getModelMode() async =>
      (await SharedPreferences.getInstance()).getString(_kModelMode) ??
      'accuracy';
  Future<void> setModelMode(String v) async =>
      (await SharedPreferences.getInstance()).setString(_kModelMode, v);

  // Emotion alert settings
  Future<String> getAlertEmotion() async =>
      (await SharedPreferences.getInstance()).getString(_kAlertEmotion) ?? '';
  Future<void> setAlertEmotion(String v) async =>
      (await SharedPreferences.getInstance()).setString(_kAlertEmotion, v);

  Future<double> getAlertThreshold() async =>
      (await SharedPreferences.getInstance()).getDouble(_kAlertThreshold) ??
      0.7;
  Future<void> setAlertThreshold(double v) async =>
      (await SharedPreferences.getInstance()).setDouble(_kAlertThreshold, v);

  Future<bool> getEmojiRainEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_kEmojiRainEnabled) ??
      true;
  Future<void> setEmojiRainEnabled(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_kEmojiRainEnabled, v);

  Future<bool> getFastEmotionResponse() async =>
      (await SharedPreferences.getInstance()).getBool(_kFastEmotionResponse) ??
      false;
  Future<void> setFastEmotionResponse(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_kFastEmotionResponse, v);
}
