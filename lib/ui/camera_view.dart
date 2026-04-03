import 'package:camera/camera.dart';
import 'package:emotion_sense/app.dart';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/presentation/providers/camera_provider.dart';
import 'package:emotion_sense/presentation/providers/face_attributes_provider.dart';
import 'package:emotion_sense/presentation/providers/settings_provider.dart';
import 'package:emotion_sense/presentation/screens/analysis_result_screen.dart';
import 'package:emotion_sense/presentation/screens/comparison_screen.dart';
import 'package:emotion_sense/presentation/screens/performance_dashboard_screen.dart';
import 'package:emotion_sense/presentation/screens/settings_screen.dart';
import 'package:emotion_sense/presentation/widgets/emoji_rain_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Main camera view matching the dark UI design.
class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  FaceAttributesProvider? _attrs;
  bool _privacyMode = true;
  bool _isCapturing = false;
  String? _alertMessage;

  void _applyRuntimeSettings(SettingsProvider settings) {
    if (_attrs == null) return;
    _attrs!.ethnicityEnabled = settings.ethnicityEnabled;
    _attrs!.targetFps = settings.targetFps;
    _attrs!.fastEmotionResponse = settings.fastEmotionResponse;
    _configureAlertFromSettings(settings);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final cam = context.read<CameraProvider>();
      final settings = context.read<SettingsProvider>();
      await cam.initialize();
      if (!mounted) return;

      final attrs = FaceAttributesProvider(cam.service);
      _attrs = attrs;
      _applyRuntimeSettings(settings);

      // Wire emotion alert callback
      _attrs!.onEmotionAlert = (emotion, confidence, faceIndex) {
        if (!mounted) return;
        setState(() {
          _alertMessage =
              '${emotion.emoji} ${emotion.label} detected (${(confidence * 100).toInt()}%)';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _alertMessage = null);
        });
      };

      _attrs!.addListener(() {
        if (mounted) setState(() {});
      });
      await _attrs!.start();
      if (!mounted) {
        await _attrs?.stop();
        _attrs?.dispose();
        _attrs = null;
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _attrs?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_attrs == null) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _attrs?.stop();
        break;
      case AppLifecycleState.resumed:
        _attrs?.start();
        break;
    }
  }

  void _configureAlertFromSettings(SettingsProvider settings) {
    _attrs?.ethnicityEnabled = settings.ethnicityEnabled;
    final alertEmotionName = settings.alertEmotion;
    if (alertEmotionName.isEmpty) {
      _attrs?.setEmotionAlert(null, 0);
      return;
    }
    final emotionMap = {
      'Happy': Emotion.happy,
      'Sad': Emotion.sad,
      'Angry': Emotion.angry,
      'Surprised': Emotion.surprised,
      'Neutral': Emotion.neutral,
    };
    final emotion = emotionMap[alertEmotionName];
    _attrs?.setEmotionAlert(emotion, settings.alertThreshold);
  }

  Future<void> _handleCapture() async {
    if (_isCapturing) return;
    final camera = context.read<CameraProvider>();
    if (camera.controller == null) return;

    setState(() => _isCapturing = true);

    try {
      // Stop stream to avoid camera conflicts
      try {
        await _attrs?.stop();
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 80));

      final img = await camera.controller!.takePicture();
      final faces = _attrs?.faces ?? [];

      final imageSize = Size(
        camera.controller!.value.previewSize?.height ?? 1920,
        camera.controller!.value.previewSize?.width ?? 1080,
      );

      if (!mounted) return;

      if (faces.isNotEmpty) {
        final face = faces.first;
        // Navigate to analysis result screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnalysisResultScreen(
              imagePath: img.path,
              faceData: face,
              imageSize: imageSize,
            ),
          ),
        );
      } else {
        // No face detected — show quick snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No face detected. Try again.'),
            backgroundColor: AppColors.surface,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Resume detection
      final resumeDelay = kIsWeb
          ? Duration.zero
          : Duration(
              milliseconds:
                  defaultTargetPlatform == TargetPlatform.iOS ? 500 : 350,
            );
      await Future.delayed(resumeDelay);
      if (!mounted) return;
      try {
        await _attrs?.start();
      } catch (_) {}
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      try {
        await _attrs?.start();
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = context.watch<CameraProvider>();
    final settings = context.watch<SettingsProvider>();
    final faces = _attrs?.faces ?? const <FaceAttributes>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: Settings | Privacy | Flash
            _buildTopBar(camera),

            // Camera preview with overlays
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Camera preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: camera.controller != null && camera.isInitialized
                          ? CameraPreview(camera.controller!)
                          : Container(
                              color: AppColors.surface,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                    ),

                    // Face bounding box overlay (blue corner brackets)
                    if (_attrs != null)
                      _FaceCornerBracketOverlay(provider: _attrs!),

                    // Emoji rain particle effect
                    if (faces.isNotEmpty && settings.emojiRainEnabled)
                      EmojiRainWidget(
                        emotion: faces.first.emotion,
                        intensity:
                            (faces.first.confidence * 0.45).clamp(0.0, 1.0),
                        enabled: settings.emojiRainEnabled,
                      ),

                    // Alert banner
                    if (_alertMessage != null)
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.notifications_active_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _alertMessage!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Face count badge (when >1 face)
                    if (faces.length > 1)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_rounded,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${faces.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Comparison mode button (bottom-right, when >=2 faces)
                    if (faces.length >= 2)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ComparisonScreen(
                                face1: faces[0],
                                face2: faces[1],
                              ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.overlay,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.5),
                                  width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.compare_arrows_rounded,
                                    color: AppColors.primary, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'COMPARE',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Emotion confidence bars (right edge)
                    if (faces.isNotEmpty)
                      Positioned(
                        right: 8,
                        top: 80,
                        bottom: 80,
                        child: _EmotionBars(face: faces.first),
                      ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (faces.isNotEmpty) ...[
                    Expanded(
                      child: settings.showAgeGender
                          ? _AttributeSummaryBar(face: faces.first)
                          : _EmotionSummaryBar(face: faces.first),
                    ),
                    const SizedBox(width: 10),
                  ],
                  GestureDetector(
                    onTap: _attrs == null
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PerformanceDashboardScreen(
                                  provider: _attrs!,
                                ),
                              ),
                            ),
                    child: _StatsPanel(
                      fps: _attrs?.currentFps ?? 0,
                      latency: _attrs?.lastLatencyMs ?? 0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Bottom controls: Gallery | Shutter | Flip
            _buildBottomControls(camera),

            // Helper text
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              child: Text(
                'TAP SHUTTER TO ANALYZE',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(CameraProvider camera) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Settings gear
          _CircleIconButton(
            icon: Icons.settings_rounded,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              // Reconfigure alerts after returning from settings
              if (mounted && _attrs != null) {
                _applyRuntimeSettings(context.read<SettingsProvider>());
                setState(() {});
              }
            },
          ),

          // Privacy toggle pill
          _PrivacyPill(
            isOn: _privacyMode,
            onToggle: () => setState(() => _privacyMode = !_privacyMode),
          ),

          // Flash toggle
          _CircleIconButton(
            icon: camera.flash == FlashMode.torch
                ? Icons.flash_on_rounded
                : Icons.flash_off_rounded,
            onTap: (!camera.isInitialized || camera.isFront)
                ? null
                : () async {
                    final next = camera.flash == FlashMode.off
                        ? FlashMode.torch
                        : FlashMode.off;
                    await camera.setFlash(next);
                    if (mounted) setState(() {});
                  },
            isActive: camera.flash == FlashMode.torch,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(CameraProvider camera) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Gallery thumbnail placeholder
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.surface,
              border: Border.all(color: AppColors.cardBorder, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Icon(
                Icons.photo_rounded,
                color: AppColors.textTertiary,
                size: 24,
              ),
            ),
          ),

          // Shutter button
          GestureDetector(
            onTap: _isCapturing ? null : _handleCapture,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.textSecondary, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isCapturing ? AppColors.textTertiary : Colors.white,
                  ),
                  child: _isCapturing
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Camera flip button
          _CircleIconButton(
            icon: Icons.cameraswitch_rounded,
            size: 56,
            onTap: () async {
              await camera.toggleCamera();
            },
          ),
        ],
      ),
    );
  }
}

/// Circular icon button with dark background.
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.size = 48,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.surface.withValues(alpha: 0.8),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.textPrimary,
          size: size * 0.45,
        ),
      ),
    );
  }
}

/// Privacy toggle pill widget.
class _PrivacyPill extends StatelessWidget {
  const _PrivacyPill({required this.isOn, required this.onToggle});

  final bool isOn;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AppColors.surface.withValues(alpha: 0.9),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_rounded,
              size: 16,
              color: isOn ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(width: 8),
            Text(
              'PRIVACY',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 10),
            _MiniToggle(isOn: isOn),
          ],
        ),
      ),
    );
  }
}

/// Mini toggle widget inside privacy pill.
class _MiniToggle extends StatelessWidget {
  const _MiniToggle({required this.isOn});

  final bool isOn;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 40,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isOn ? AppColors.primary : AppColors.surfaceLight,
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Stats panel showing FPS, latency, and model info.
class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.fps, required this.latency});

  final double fps;
  final double latency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CompactStat(
              label: 'FPS',
              value: fps.toStringAsFixed(1),
              color: AppColors.accentGold),
          const SizedBox(width: 14),
          _CompactStat(
              label: 'LAT',
              value: '${latency.toInt()}ms',
              color: AppColors.accent),
          const SizedBox(width: 14),
          _CompactStat(
              label: 'MODEL', value: 'V2', color: AppColors.textPrimary),
        ],
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _AttributeSummaryBar extends StatelessWidget {
  const _AttributeSummaryBar({required this.face});

  final FaceAttributes face;

  @override
  Widget build(BuildContext context) {
    final ethnicity = face.ethnicity;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatRow(
              label: 'AGE',
              value: face.ageRange,
              color: AppColors.accentGold,
            ),
          ),
          Expanded(
            child: _StatRow(
              label: 'GENDER',
              value: face.gender,
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: _StatRow(
              label: 'ETHNIC',
              value: (ethnicity == null || ethnicity.isEmpty)
                  ? 'Unknown'
                  : ethnicity,
              color: ethnicity == null ||
                      ethnicity.isEmpty ||
                      ethnicity == 'Unknown'
                  ? AppColors.textTertiary
                  : AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmotionSummaryBar extends StatelessWidget {
  const _EmotionSummaryBar({required this.face});

  final FaceAttributes face;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Text(face.emotion.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  face.emotion.label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(face.confidence * 100).round()}% confidence',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Vertical emotion confidence bars on the right edge.
class _EmotionBars extends StatelessWidget {
  const _EmotionBars({required this.face});

  final FaceAttributes face;

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.accent, AppColors.surprised, Color(0xFF00BCD4)];
    final values = [
      face.confidence,
      (face.rawSmileProb ?? 0.5),
      ((face.leftEyeOpenProb ?? 0.5) + (face.rightEyeOpenProb ?? 0.5)) / 2,
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Container(
            width: 6,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: colors[i].withValues(alpha: 0.2),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 6,
                height: 60 * values[i].clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: colors[i],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Blue corner-bracket face overlay (matching screenshot design).
class _FaceCornerBracketOverlay extends StatelessWidget {
  const _FaceCornerBracketOverlay({required this.provider});
  final FaceAttributesProvider provider;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: provider,
      builder: (context, _) {
        return CustomPaint(
          painter: _CornerBracketPainter(provider.faces),
        );
      },
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  _CornerBracketPainter(this.faces);
  final List<FaceAttributes> faces;

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in faces) {
      final rect = Rect.fromLTWH(
        f.rect.left * size.width,
        f.rect.top * size.height,
        f.rect.width * size.width,
        f.rect.height * size.height,
      );

      // Draw blue corner brackets
      final paint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      final cornerLen = (rect.width * 0.15).clamp(12.0, 30.0);

      // Top-left
      canvas.drawLine(
        Offset(rect.left, rect.top + cornerLen),
        Offset(rect.left, rect.top),
        paint,
      );
      canvas.drawLine(
        Offset(rect.left, rect.top),
        Offset(rect.left + cornerLen, rect.top),
        paint,
      );

      // Top-right
      canvas.drawLine(
        Offset(rect.right - cornerLen, rect.top),
        Offset(rect.right, rect.top),
        paint,
      );
      canvas.drawLine(
        Offset(rect.right, rect.top),
        Offset(rect.right, rect.top + cornerLen),
        paint,
      );

      // Bottom-left
      canvas.drawLine(
        Offset(rect.left, rect.bottom - cornerLen),
        Offset(rect.left, rect.bottom),
        paint,
      );
      canvas.drawLine(
        Offset(rect.left, rect.bottom),
        Offset(rect.left + cornerLen, rect.bottom),
        paint,
      );

      // Bottom-right
      canvas.drawLine(
        Offset(rect.right - cornerLen, rect.bottom),
        Offset(rect.right, rect.bottom),
        paint,
      );
      canvas.drawLine(
        Offset(rect.right, rect.bottom),
        Offset(rect.right, rect.bottom - cornerLen),
        paint,
      );

      // Thin crosshair lines through center
      final cx = rect.center.dx;
      final cy = rect.center.dy;
      final crossPaint = Paint()
        ..color = AppColors.textSecondary.withValues(alpha: 0.25)
        ..strokeWidth = 0.5;

      canvas.drawLine(
        Offset(rect.left + cornerLen, cy),
        Offset(rect.right - cornerLen, cy),
        crossPaint,
      );
      canvas.drawLine(
        Offset(cx, rect.top + cornerLen),
        Offset(cx, rect.bottom - cornerLen),
        crossPaint,
      );

      // Center dot
      canvas.drawCircle(
        Offset(cx, cy),
        3,
        Paint()..color = AppColors.primary.withValues(alpha: 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) {
    if (identical(oldDelegate.faces, faces)) return false;
    if (oldDelegate.faces.length != faces.length) return true;
    for (var i = 0; i < faces.length; i++) {
      if (oldDelegate.faces[i].rect != faces[i].rect) return true;
    }
    return false;
  }
}
