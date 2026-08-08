import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/presentation/LyricsEmotion/models/lyric_emotion_model.dart';

class EmotionBackgroundPainter extends CustomPainter {
  final EmotionType dominantEmotion;
  final double animationValue;

  EmotionBackgroundPainter({
    required this.dominantEmotion,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGradientBackground(canvas, size);
    _drawParticles(canvas, size);
  }

  void _drawGradientBackground(Canvas canvas, Size size) {
    final colors = _emotionGradientColors(dominantEmotion);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colors.$1.withOpacity(0.15),
        const Color(0xFF121212),
        colors.$2.withOpacity(0.10),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _drawParticles(Canvas canvas, Size size) {
    final colors = _emotionGradientColors(dominantEmotion);
    final random = Random(42);
    final particleCount = 20;

    for (int i = 0; i < particleCount; i++) {
      final baseX = random.nextDouble() * size.width;
      final speed = 0.3 + random.nextDouble() * 0.7;
      final yOffset = (animationValue * size.height * speed) % size.height;
      final y = size.height - yOffset;
      final radius = (1.5 + random.nextDouble() * 3.0).r;
      final opacity = (0.05 + random.nextDouble() * 0.15) *
          (0.5 + 0.5 * sin(animationValue * pi * 2 + i));

      final paint = Paint()
        ..color = colors.$1.withOpacity(opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius);

      canvas.drawCircle(
        Offset(baseX, y),
        radius,
        paint,
      );
    }
  }

  (Color, Color) _emotionGradientColors(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.love:
        return (const Color(0xFFE91E63), const Color(0xFFAD1457));
      case EmotionType.sadness:
        return (const Color(0xFF1565C0), const Color(0xFF0D47A1));
      case EmotionType.joy:
        return (const Color(0xFFFFC107), const Color(0xFFFFA000));
      case EmotionType.anger:
        return (const Color(0xFFD32F2F), const Color(0xFFB71C1C));
      case EmotionType.hope:
        return (const Color(0xFF26A69A), const Color(0xFF00897B));
      case EmotionType.calm:
        return (const Color(0xFF7B2FBE), const Color(0xFF5B21B6));
      case EmotionType.energy:
        return (const Color(0xFFFF6F00), const Color(0xFFE65100));
      case EmotionType.pain:
        return (const Color(0xFF6A1B9A), const Color(0xFF4A148C));
    }
  }

  @override
  bool shouldRepaint(covariant EmotionBackgroundPainter oldDelegate) {
    return oldDelegate.dominantEmotion != dominantEmotion ||
        oldDelegate.animationValue != animationValue;
  }
}

class EmotionBackground extends StatefulWidget {
  final EmotionType dominantEmotion;

  const EmotionBackground({super.key, required this.dominantEmotion});

  @override
  State<EmotionBackground> createState() => _EmotionBackgroundState();
}

class _EmotionBackgroundState extends State<EmotionBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant EmotionBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dominantEmotion != widget.dominantEmotion) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: EmotionBackgroundPainter(
            dominantEmotion: widget.dominantEmotion,
            animationValue: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}
