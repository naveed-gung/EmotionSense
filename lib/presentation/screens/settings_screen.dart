import 'package:emotion_sense/app.dart';
import 'package:emotion_sense/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Top bar: back + title
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface.withValues(alpha: 0.8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // App icon header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Icon(
                        Icons.face_retouching_natural_rounded,
                        color: AppColors.textPrimary,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'EmotionSense',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v1.0.0 • On-Device AI',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ANALYSIS section
            _SectionHeader(title: 'ANALYSIS'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _SettingsToggle(
                  icon: Icons.timeline_rounded,
                  title: 'Temporal Smoothing',
                  subtitle: 'Reduce prediction flickering',
                  value: true, // Always on for stability
                  onChanged: (_) {},
                ),
                const Divider(color: AppColors.cardBorder, height: 1),
                _SettingsSlider(
                  icon: Icons.tune_rounded,
                  title: 'Detection Sensitivity',
                  value: s.sensitivity,
                  min: 0.3,
                  max: 0.9,
                  label: '${(s.sensitivity * 100).toInt()}%',
                  onChanged: (v) => s.setSensitivity(v),
                ),
                const Divider(color: AppColors.cardBorder, height: 1),
                _SettingsSlider(
                  icon: Icons.speed_rounded,
                  title: 'Analysis FPS',
                  value: s.targetFps.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 5,
                  label: '${s.targetFps}',
                  onChanged: (v) => s.setTargetFps(v.round()),
                ),
                const Divider(color: AppColors.cardBorder, height: 1),
                _SettingsToggle(
                  icon: Icons.flash_on_rounded,
                  title: 'Fast Emotion Response',
                  subtitle: 'Snappier smile changes with less smoothing',
                  value: s.fastEmotionResponse,
                  onChanged: (v) => s.setFastEmotionResponse(v),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // CLASSIFICATION section
            _SectionHeader(title: 'CLASSIFICATION'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _SettingsToggle(
                  icon: Icons.person_rounded,
                  title: 'Show Age & Gender',
                  subtitle: 'Display demographic predictions',
                  value: s.showAgeGender,
                  onChanged: (v) => s.setShowAgeGender(v),
                ),
                const Divider(color: AppColors.cardBorder, height: 1),
                _SettingsToggle(
                  icon: Icons.public_rounded,
                  title: 'Ethnicity Classification',
                  subtitle: 'Sensitive attribute — opt-in only',
                  value: s.ethnicityEnabled,
                  onChanged: (v) => s.setEthnicityEnabled(v),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // MODEL section
            _SectionHeader(title: 'MODEL'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.memory_rounded,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Performance Mode',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              s.modelMode == 'speed'
                                  ? '4 threads · faster inference'
                                  : '2 threads · higher accuracy',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _ModeToggle(
                        isSpeed: s.modelMode == 'speed',
                        onChanged: (isSpeed) {
                          s.setModelMode(isSpeed ? 'speed' : 'accuracy');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ALERTS section
            _SectionHeader(title: 'EMOTION ALERTS'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active_rounded,
                          color: AppColors.danger, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Alert Emotion',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              s.alertEmotion.isEmpty
                                  ? 'Disabled — no alerts'
                                  : 'Alert when ${s.alertEmotion} detected',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _EmotionDropdown(
                        value: s.alertEmotion,
                        onChanged: (v) => s.setAlertEmotion(v),
                      ),
                    ],
                  ),
                ),
                if (s.alertEmotion.isNotEmpty) ...[
                  const Divider(color: AppColors.cardBorder, height: 1),
                  _SettingsSlider(
                    icon: Icons.trending_up_rounded,
                    title: 'Alert Threshold',
                    value: s.alertThreshold,
                    min: 0.3,
                    max: 0.95,
                    divisions: 13,
                    label: '${(s.alertThreshold * 100).toInt()}%',
                    onChanged: (v) => s.setAlertThreshold(v),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // CAPTURE section
            _SectionHeader(title: 'CAPTURE'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _SettingsToggle(
                  icon: Icons.camera_alt_rounded,
                  title: 'Auto Capture',
                  subtitle: 'Capture on strong emotion detected',
                  value: s.autoCapture,
                  onChanged: (v) => s.setAutoCapture(v),
                ),
                if (s.autoCapture) ...[
                  const Divider(color: AppColors.cardBorder, height: 1),
                  _SettingsSlider(
                    icon: Icons.verified_rounded,
                    title: 'Auto Capture Confidence',
                    value: s.autoCaptureConfidence,
                    min: 0.5,
                    max: 0.95,
                    divisions: 9,
                    label: '${(s.autoCaptureConfidence * 100).toInt()}%',
                    onChanged: (v) => s.setAutoCaptureConfidence(v),
                  ),
                  const Divider(color: AppColors.cardBorder, height: 1),
                  _SettingsSlider(
                    icon: Icons.timer_rounded,
                    title: 'Cooldown',
                    value: s.autoCaptureCooldownSec.toDouble(),
                    min: 3,
                    max: 20,
                    divisions: 17,
                    label: '${s.autoCaptureCooldownSec}s',
                    onChanged: (v) => s.setAutoCaptureCooldownSec(v.round()),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // FEEDBACK section
            _SectionHeader(title: 'FEEDBACK'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _SettingsToggle(
                  icon: Icons.volume_up_rounded,
                  title: 'Sound Effects',
                  value: s.soundOn,
                  onChanged: (v) => s.setSoundOn(v),
                ),
                const Divider(color: AppColors.cardBorder, height: 1),
                _SettingsToggle(
                  icon: Icons.vibration_rounded,
                  title: 'Haptic Feedback',
                  value: s.hapticOn,
                  onChanged: (v) => s.setHapticOn(v),
                ),
                const Divider(color: AppColors.cardBorder, height: 1),
                _SettingsToggle(
                  icon: Icons.emoji_emotions_rounded,
                  title: 'Emoji Rain Effects',
                  subtitle: 'Floating emoji particles on emotion changes',
                  value: s.emojiRainEnabled,
                  onChanged: (v) => s.setEmojiRainEnabled(v),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // PRIVACY section
            _SectionHeader(title: 'PRIVACY'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.shield_rounded,
                          color: AppColors.accent, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Zero-Cloud Promise',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All analysis happens on-device. No images or data ever leave your phone.',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // About footer
            Center(
              child: Text(
                'EmotionSense • Built with Flutter & TFLite',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Reset onboarding
            Center(
              child: GestureDetector(
                onTap: () {
                  s.setHasSeenOnboarding(false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          const Text('Onboarding will show on next launch'),
                      backgroundColor: AppColors.surface,
                    ),
                  );
                },
                child: Text(
                  'Show Onboarding Again',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            inactiveThumbColor: AppColors.textTertiary,
            inactiveTrackColor: AppColors.surfaceLight,
          ),
        ],
      ),
    );
  }
}

class _SettingsSlider extends StatelessWidget {
  const _SettingsSlider({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.onChanged,
    this.divisions,
  });

  final IconData icon;
  final String title;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String label;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Accuracy / Speed mode toggle pill.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.isSpeed, required this.onChanged});
  final bool isSpeed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.surfaceLight,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => onChanged(false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: !isSpeed ? AppColors.primary : Colors.transparent,
              ),
              child: Text(
                '🎯',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isSpeed ? AppColors.accentGold : Colors.transparent,
              ),
              child: Text(
                '⚡',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dropdown to select an emotion for alerts.
class _EmotionDropdown extends StatelessWidget {
  const _EmotionDropdown({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = ['', 'Happy', 'Sad', 'Angry', 'Surprised', 'Neutral'];
    final labels = [
      'Off',
      '😄 Happy',
      '😢 Sad',
      '😠 Angry',
      '😲 Surprised',
      '😐 Neutral'
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.surfaceLight,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppColors.surface,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          icon: Icon(Icons.arrow_drop_down,
              color: AppColors.textTertiary, size: 18),
          items: List.generate(options.length, (i) {
            return DropdownMenuItem(
              value: options[i],
              child: Text(labels[i]),
            );
          }),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
