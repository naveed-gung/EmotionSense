import 'dart:math';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:flutter/material.dart';

/// Subtle particle effect showing falling emojis matching the detected emotion.
class EmojiRainWidget extends StatefulWidget {
  const EmojiRainWidget({
    super.key,
    required this.emotion,
    this.intensity = 0.5,
    this.enabled = true,
  });

  final Emotion emotion;
  final double intensity; // 0..1 controls density
  final bool enabled;

  @override
  State<EmojiRainWidget> createState() => _EmojiRainWidgetState();
}

class _EmojiRainWidgetState extends State<EmojiRainWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_EmojiParticle> _particles = [];
  final _random = Random();
  Emotion? _lastEmotion;

  static const _maxParticles = 20;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tick);
    if (widget.enabled) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant EmojiRainWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
      _particles.clear();
    }
    if (widget.emotion != _lastEmotion) {
      _particles.clear();
      _lastEmotion = widget.emotion;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tick() {
    if (!mounted || !widget.enabled) return;

    // Spawn new particles based on intensity
    final spawnChance = widget.intensity * 0.3;
    if (_particles.length < _maxParticles &&
        _random.nextDouble() < spawnChance) {
      _particles.add(_EmojiParticle(
        x: _random.nextDouble(),
        y: -0.05,
        speed: 0.003 + _random.nextDouble() * 0.005,
        size: 14.0 + _random.nextDouble() * 12.0,
        drift: (_random.nextDouble() - 0.5) * 0.002,
        opacity: 0.4 + _random.nextDouble() * 0.4,
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.05,
      ));
    }

    // Update particles
    for (final p in _particles) {
      p.y += p.speed;
      p.x += p.drift;
      p.rotation += p.rotationSpeed;
      // Fade out near bottom
      if (p.y > 0.8) {
        p.opacity *= 0.96;
      }
    }

    // Remove dead particles
    _particles.removeWhere((p) => p.y > 1.1 || p.opacity < 0.05);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _particles.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final emoji = widget.emotion.emoji;

          return Stack(
            children: _particles.map((p) {
              return Positioned(
                left: p.x * w - p.size / 2,
                top: p.y * h - p.size / 2,
                child: Transform.rotate(
                  angle: p.rotation,
                  child: Opacity(
                    opacity: p.opacity.clamp(0.0, 1.0),
                    child: Text(
                      emoji,
                      style: TextStyle(fontSize: p.size),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _EmojiParticle {
  double x;
  double y;
  double speed;
  double size;
  double drift;
  double opacity;
  double rotation;
  double rotationSpeed;

  _EmojiParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.drift,
    required this.opacity,
    required this.rotation,
    required this.rotationSpeed,
  });
}
