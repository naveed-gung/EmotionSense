import 'dart:async';
import 'package:emotion_sense/app.dart';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/presentation/providers/face_attributes_provider.dart';
import 'package:flutter/material.dart';

/// In-app developer tools showing inference time per model, memory, and FPS history.
class PerformanceDashboardScreen extends StatefulWidget {
  const PerformanceDashboardScreen({
    super.key,
    required this.provider,
  });

  final FaceAttributesProvider provider;

  @override
  State<PerformanceDashboardScreen> createState() =>
      _PerformanceDashboardScreenState();
}

class _PerformanceDashboardScreenState
    extends State<PerformanceDashboardScreen> {
  Timer? _timer;
  final List<double> _fpsHistory = [];
  final List<double> _latencyHistory = [];
  static const _maxHistory = 60;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() {
        _fpsHistory.add(widget.provider.currentFps);
        _latencyHistory.add(widget.provider.lastLatencyMs);
        if (_fpsHistory.length > _maxHistory) _fpsHistory.removeAt(0);
        if (_latencyHistory.length > _maxHistory) _latencyHistory.removeAt(0);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faces = widget.provider.faces;
    final fps = widget.provider.currentFps;
    final latency = widget.provider.lastLatencyMs;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Top bar
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Performance',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Developer Tools',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: fps >= 10
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : AppColors.danger.withValues(alpha: 0.15),
                  ),
                  child: Text(
                    '${fps.toStringAsFixed(1)} FPS',
                    style: TextStyle(
                      color: fps >= 10 ? AppColors.accent : AppColors.danger,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Live metrics row
            Row(
              children: [
                _MetricCard(
                  title: 'FPS',
                  value: fps.toStringAsFixed(1),
                  unit: 'frames/s',
                  color: AppColors.accentGold,
                  icon: Icons.speed_rounded,
                ),
                const SizedBox(width: 12),
                _MetricCard(
                  title: 'LATENCY',
                  value: latency.toInt().toString(),
                  unit: 'ms/frame',
                  color: AppColors.primary,
                  icon: Icons.timer_rounded,
                ),
                const SizedBox(width: 12),
                _MetricCard(
                  title: 'FACES',
                  value: faces.length.toString(),
                  unit: 'detected',
                  color: AppColors.accent,
                  icon: Icons.face_rounded,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // FPS History Chart
            _SectionHeader(title: 'FPS HISTORY'),
            const SizedBox(height: 8),
            _MiniChart(
              data: _fpsHistory,
              maxValue: 30,
              color: AppColors.accentGold,
              height: 100,
            ),

            const SizedBox(height: 20),

            // Latency History Chart
            _SectionHeader(title: 'LATENCY HISTORY'),
            const SizedBox(height: 8),
            _MiniChart(
              data: _latencyHistory,
              maxValue: 200,
              color: AppColors.primary,
              height: 100,
            ),

            const SizedBox(height: 20),

            // Model Info
            _SectionHeader(title: 'MODEL PIPELINE'),
            const SizedBox(height: 8),
            _ModelInfoCard(
              models: const [
                _ModelInfo(
                  name: 'Face Detection',
                  type: 'ML Kit (Google)',
                  detail: 'Short Range',
                ),
                _ModelInfo(
                  name: 'Age Estimation',
                  type: 'TFLite',
                  detail: 'model_lite_age_q',
                ),
                _ModelInfo(
                  name: 'Gender Classification',
                  type: 'TFLite',
                  detail: 'model_lite_gender_q',
                ),
                _ModelInfo(
                  name: 'Ethnicity Classification',
                  type: 'TFLite',
                  detail: 'age_gender_ethnicity_new',
                ),
                _ModelInfo(
                  name: 'Emotion Detection',
                  type: 'ML Kit Heuristics',
                  detail: 'Smile + Eye + Landmark',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Per-face details
            if (faces.isNotEmpty) ...[
              _SectionHeader(title: 'ACTIVE FACES (${faces.length})'),
              const SizedBox(height: 8),
              ...faces.asMap().entries.map((e) {
                final i = e.key;
                final f = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _FaceDetailCard(index: i, face: f),
                );
              }),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              unit,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
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
        letterSpacing: 1.5,
      ),
    );
  }
}

class _MiniChart extends StatelessWidget {
  const _MiniChart({
    required this.data,
    required this.maxValue,
    required this.color,
    required this.height,
  });

  final List<double> data;
  final double maxValue;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: CustomPaint(
          size: Size(double.infinity, height),
          painter: _ChartPainter(data: data, maxValue: maxValue, color: color),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.data,
    required this.maxValue,
    required this.color,
  });

  final List<double> data;
  final double maxValue;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.3),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y =
          size.height - (data[i].clamp(0, maxValue) / maxValue * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo((data.length - 1) * stepX, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => true;
}

class _ModelInfo {
  const _ModelInfo({
    required this.name,
    required this.type,
    required this.detail,
  });

  final String name;
  final String type;
  final String detail;
}

class _ModelInfoCard extends StatelessWidget {
  const _ModelInfoCard({required this.models});
  final List<_ModelInfo> models;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        children: models.asMap().entries.map((e) {
          final i = e.key;
          final m = e.value;
          return Column(
            children: [
              if (i > 0)
                Divider(
                    color: AppColors.cardBorder, height: 16, thickness: 0.5),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${m.type} · ${m.detail}',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _FaceDetailCard extends StatelessWidget {
  const _FaceDetailCard({required this.index, required this.face});
  final int index;
  final FaceAttributes face;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Text(face.emotion.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Face #${index + 1} ${face.trackingId != null ? "(ID: ${face.trackingId})" : ""}',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${face.emotion.label} · ${face.gender} · ${face.ageRange}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(face.confidence * 100).toInt()}%',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
