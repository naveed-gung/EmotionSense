import 'package:flutter/material.dart';
import 'package:emotion_sense/data/models/face_data.dart';

class FaceOverlayPainter extends CustomPainter {
  FaceOverlayPainter({required this.face});
  final FaceData? face;

  @override
  void paint(Canvas canvas, Size size) {
    if (face == null) return;
    final paint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(face!.boundingBox, paint);
  }

  @override
  bool shouldRepaint(covariant FaceOverlayPainter oldDelegate) {
    // Only repaint if the bounding box actually changed
    if (oldDelegate.face == null && face == null) return false;
    if (oldDelegate.face == null || face == null) return true;
    
    final oldBox = oldDelegate.face!.boundingBox;
    final newBox = face!.boundingBox;
    
    // Check if bounding box values are different (with small tolerance for floating point)
    return (oldBox.left - newBox.left).abs() > 0.5 ||
           (oldBox.top - newBox.top).abs() > 0.5 ||
           (oldBox.width - newBox.width).abs() > 0.5 ||
           (oldBox.height - newBox.height).abs() > 0.5;
  }
}
