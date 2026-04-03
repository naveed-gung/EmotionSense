import 'package:emotion_sense/app.dart';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/presentation/providers/face_attributes_provider.dart';
import 'package:flutter/material.dart';

/// Side-by-side two-person emotion comparison screen.
/// Uses the multi-face data from the face attributes provider.
class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({
    super.key,
    required this.face1,
    required this.face2,
  });

  final FaceAttributes face1;
  final FaceAttributes face2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface.withValues(alpha: 0.8),
                        border:
                            Border.all(color: AppColors.cardBorder, width: 1),
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
                    'Face Comparison',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.primary.withValues(alpha: 0.15),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'LIVE',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Two side-by-side face cards
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _FaceCard(face: face1, label: 'Person 1')),
                    const SizedBox(width: 12),
                    Expanded(child: _FaceCard(face: face2, label: 'Person 2')),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Comparison summary
            _ComparisonSummary(face1: face1, face2: face2),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FaceCard extends StatelessWidget {
  const _FaceCard({required this.face, required this.label});
  final FaceAttributes face;
  final String label;

  @override
  Widget build(BuildContext context) {
    final emotion = face.emotion;
    final conf = (face.confidence * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Label
          Text(
            label,
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),

          // Big emoji
          Text(emotion.emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 12),

          // Emotion name
          Text(
            emotion.label.toUpperCase(),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$conf% confidence',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 20),

          // Attributes
          _AttrRow(icon: Icons.person_rounded, text: face.gender),
          const SizedBox(height: 6),
          _AttrRow(icon: Icons.calendar_today_rounded, text: face.ageRange),
          if (face.ethnicity != null &&
              face.ethnicity!.isNotEmpty &&
              face.ethnicity != 'Unknown') ...[
            const SizedBox(height: 6),
            _AttrRow(icon: Icons.public_rounded, text: face.ethnicity!),
          ],

          const SizedBox(height: 16),

          // Head pose
          if (face.headEulerAngleY != null) ...[
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 12),
            Text(
              'HEAD POSE',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PoseValue(
                    label: 'YAW',
                    value: face.headEulerAngleY?.toStringAsFixed(0) ?? '-'),
                _PoseValue(
                    label: 'PITCH',
                    value: face.headEulerAngleX?.toStringAsFixed(0) ?? '-'),
                _PoseValue(
                    label: 'ROLL',
                    value: face.headEulerAngleZ?.toStringAsFixed(0) ?? '-'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AttrRow extends StatelessWidget {
  const _AttrRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PoseValue extends StatelessWidget {
  const _PoseValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value°',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _ComparisonSummary extends StatelessWidget {
  const _ComparisonSummary({required this.face1, required this.face2});
  final FaceAttributes face1;
  final FaceAttributes face2;

  @override
  Widget build(BuildContext context) {
    final match = face1.emotion == face2.emotion;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: match
              ? AppColors.accent.withValues(alpha: 0.4)
              : AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            match ? Icons.link_rounded : Icons.link_off_rounded,
            color: match ? AppColors.accent : AppColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            match
                ? 'EMOTIONS MATCH — ${face1.emotion.label.toUpperCase()}'
                : 'DIFFERENT EMOTIONS',
            style: TextStyle(
              color: match ? AppColors.accent : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
