import 'package:emotion_sense/app.dart';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/data/models/age_gender_data.dart';
import 'package:emotion_sense/presentation/providers/face_attributes_provider.dart';
import 'package:emotion_sense/presentation/providers/history_provider.dart';
import 'package:emotion_sense/presentation/widgets/platform_path_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Full-screen analysis result screen matching the dark UI design.
class AnalysisResultScreen extends StatelessWidget {
  const AnalysisResultScreen({
    super.key,
    required this.imagePath,
    required this.faceData,
    required this.imageSize,
  });

  final String imagePath;
  final FaceAttributes faceData;
  final Size imageSize;

  @override
  Widget build(BuildContext context) {
    final emotion = faceData.emotion;
    final confidence = (faceData.confidence * 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: back arrow + badge
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
                  const Spacer(),
                  // "ANALYSIS COMPLETE" badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.accent.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: AppColors.accent, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'ANALYSIS COMPLETE',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            // Image with corner brackets
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PlatformPathImage(
                        path: imagePath,
                        fit: BoxFit.cover,
                      ),
                      // Corner brackets overlay on face area
                      CustomPaint(
                        painter: _ResultCornerBracketPainter(faceData.rect),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Main emotion result
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder, width: 1),
              ),
              child: Column(
                children: [
                  // Emotion emoji + name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        emotion.emoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emotion.label.toUpperCase(),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            '$confidence% confidence',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          if (faceData.ageRange.isNotEmpty &&
                              faceData.ageRange != '-')
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                [
                                  'Age ${faceData.ageRange.replaceAll('~', '')}',
                                  if (faceData.gender != 'Unknown')
                                    faceData.gender,
                                ].join('  |  '),
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Chips: Gender, Age, Ethnicity
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _Chip(
                        icon: Icons.person_rounded,
                        label: faceData.gender,
                        color: AppColors.primary,
                      ),
                      _Chip(
                        icon: Icons.calendar_today_rounded,
                        label: faceData.ageRange.replaceAll('~', ''),
                        color: AppColors.accentGold,
                      ),
                      if (faceData.ethnicity != null &&
                          faceData.ethnicity!.isNotEmpty &&
                          faceData.ethnicity != 'Unknown')
                        _Chip(
                          icon: Icons.public_rounded,
                          label: faceData.ethnicity!,
                          color: AppColors.accent,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons: Discard | Save
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16)
                  .copyWith(bottom: 16),
              child: Row(
                children: [
                  // Discard
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: AppColors.surface,
                          border:
                              Border.all(color: AppColors.cardBorder, width: 1),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close_rounded,
                                  color: AppColors.textSecondary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Discard',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Save
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _save(context),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_alt_rounded,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    try {
      final history = context.read<HistoryProvider>();
      final ageGenderData = AgeGenderData(
        ageRange: faceData.ageRange,
        gender: faceData.gender,
        confidence: faceData.confidence,
      );
      await history.addCapture(
        imagePath: imagePath,
        emotion: faceData.emotion,
        confidence: faceData.confidence,
        ageGender: ageGenderData,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved to history!'),
            backgroundColor: AppColors.accent.withValues(alpha: 0.9),
            duration: const Duration(seconds: 1),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }
}

/// Chip widget for gender/age/ethnicity.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Corner bracket painter for the result screen.
class _ResultCornerBracketPainter extends CustomPainter {
  _ResultCornerBracketPainter(this.faceRect);
  final Rect faceRect;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      faceRect.left * size.width,
      faceRect.top * size.height,
      faceRect.width * size.width,
      faceRect.height * size.height,
    );

    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final cornerLen = (rect.width * 0.15).clamp(12.0, 30.0);

    // Top-left
    canvas.drawLine(Offset(rect.left, rect.top + cornerLen),
        Offset(rect.left, rect.top), paint);
    canvas.drawLine(Offset(rect.left, rect.top),
        Offset(rect.left + cornerLen, rect.top), paint);

    // Top-right
    canvas.drawLine(Offset(rect.right - cornerLen, rect.top),
        Offset(rect.right, rect.top), paint);
    canvas.drawLine(Offset(rect.right, rect.top),
        Offset(rect.right, rect.top + cornerLen), paint);

    // Bottom-left
    canvas.drawLine(Offset(rect.left, rect.bottom - cornerLen),
        Offset(rect.left, rect.bottom), paint);
    canvas.drawLine(Offset(rect.left, rect.bottom),
        Offset(rect.left + cornerLen, rect.bottom), paint);

    // Bottom-right
    canvas.drawLine(Offset(rect.right - cornerLen, rect.bottom),
        Offset(rect.right, rect.bottom), paint);
    canvas.drawLine(Offset(rect.right, rect.bottom),
        Offset(rect.right, rect.bottom - cornerLen), paint);
  }

  @override
  bool shouldRepaint(covariant _ResultCornerBracketPainter old) =>
      old.faceRect != faceRect;
}
