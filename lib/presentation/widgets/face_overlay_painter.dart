import 'package:flutter/material.dart';
import 'package:emotion_sense/app.dart';

/// Blue corner-bracket face overlay painter.
class FaceOverlayPainter extends CustomPainter {
  FaceOverlayPainter({required this.normalizedRect});
  final Rect? normalizedRect;

  @override
  void paint(Canvas canvas, Size size) {
    if (normalizedRect == null) return;
    final rect = Rect.fromLTWH(
      normalizedRect!.left * size.width,
      normalizedRect!.top * size.height,
      normalizedRect!.width * size.width,
      normalizedRect!.height * size.height,
    );

    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
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
  bool shouldRepaint(covariant FaceOverlayPainter oldDelegate) =>
      oldDelegate.normalizedRect != normalizedRect;
}
