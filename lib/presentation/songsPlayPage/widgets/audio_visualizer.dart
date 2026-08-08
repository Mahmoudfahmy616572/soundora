import 'dart:math' show Random, sin, cos, min;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';

enum VisualizerMode { bars, wave, circular }

class AudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final VisualizerMode mode;
  final double height;
  final Color? color;

  const AudioVisualizer({
    super.key,
    this.isPlaying = true,
    this.mode = VisualizerMode.bars,
    this.height = 120,
    this.color,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _glowController;
  final List<double> _barHeights = List.generate(32, (_) => 0.0);
  final Random _random = Random();
  double _glowPhase = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addListener(_updateBars);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
    )..addListener(_updateGlow);

    if (widget.isPlaying) _startAnimation();
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startAnimation();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _stopAnimation();
    }
  }

  void _startAnimation() {
    _controller.repeat(reverse: true);
    _glowController.repeat();
  }

  void _stopAnimation() {
    _controller.stop();
    _glowController.stop();
  }

  void _updateBars() {
    for (int i = 0; i < _barHeights.length; i++) {
      final centerBias = 1 -
          (i - _barHeights.length / 2).abs() / (_barHeights.length / 2);
      final base = 0.15 + centerBias * 0.35;
      final variation = _random.nextDouble() * 0.5 * centerBias;
      _barHeights[i] = (base + variation).clamp(0.1, 1.0);
    }
    setState(() {});
  }

  void _updateGlow() {
    _glowPhase = (_glowPhase + 0.12) % (2 * 3.14159);
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.color ?? AppColors.primaryColor;

    return SizedBox(
      height: widget.height.h,
      width: double.infinity,
      child: _buildVisualizer(accentColor),
    );
  }

  Widget _buildVisualizer(Color accentColor) {
    switch (widget.mode) {
      case VisualizerMode.bars:
        return _buildBars(accentColor);
      case VisualizerMode.wave:
        return _buildWave(accentColor);
      case VisualizerMode.circular:
        return _buildCircular(accentColor);
    }
  }

  Widget _buildBars(Color accentColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_barHeights.length, (i) {
        final h = widget.isPlaying ? _barHeights[i] : 0.1;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 1.w),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 6.w,
            height: (h * widget.height * 0.85).h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3.r),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  accentColor.withOpacity(0.4),
                  accentColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity((0.3 + _glowPhase * 0.1).clamp(0.0, 1.0)),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWave(Color accentColor) {
    return CustomPaint(
      size: Size(double.infinity, widget.height.h),
      painter: _WavePainter(
        isPlaying: widget.isPlaying,
        color: accentColor,
        barHeights: _barHeights,
        glowPhase: _glowPhase,
      ),
    );
  }

  Widget _buildCircular(Color accentColor) {
    return Center(
      child: CustomPaint(
        size: Size(widget.height.h, widget.height.h),
        painter: _CircularPainter(
          isPlaying: widget.isPlaying,
          color: accentColor,
          barHeights: _barHeights,
          glowPhase: _glowPhase,
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final bool isPlaying;
  final Color color;
  final List<double> barHeights;
  final double glowPhase;

  _WavePainter({
    required this.isPlaying,
    required this.color,
    required this.barHeights,
    required this.glowPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final midY = size.height / 2;
    final step = size.width / (barHeights.length - 1);

    path.moveTo(0, midY);
    fillPath.moveTo(0, size.height);

    for (int i = 0; i < barHeights.length; i++) {
      final x = i * step;
      final amplitude = isPlaying ? barHeights[i] * size.height * 0.4 : 0;
      final y = midY - amplitude * sin(i * 0.5 + glowPhase);

      if (i == 0) {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * step;
        final cpX = (prevX + x) / 2;
        path.quadraticBezierTo(cpX, y, x, y);
        fillPath.quadraticBezierTo(cpX, y, x, y);
      }
    }

    path.lineTo(size.width, midY);
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    paint.shader = LinearGradient(
      colors: [
        color.withOpacity(0.8),
        color,
        color.withOpacity(0.8),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);

    fillPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.3),
        color.withOpacity(0.05),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => true;
}

class _CircularPainter extends CustomPainter {
  final bool isPlaying;
  final Color color;
  final List<double> barHeights;
  final double glowPhase;

  _CircularPainter({
    required this.isPlaying,
    required this.color,
    required this.barHeights,
    required this.glowPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = min(size.width, size.height) * 0.25;
    final barCount = barHeights.length;

    final innerPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), radius * 0.6, innerPaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), radius, ringPaint);

    for (int i = 0; i < barCount; i++) {
      final angle = (2 * 3.14159265 / barCount) * i - 3.14159265 / 2;
      final h = isPlaying ? barHeights[i] * radius * 0.9 : 2.0;

      final startR = radius;
      final endR = radius + h;

      final startX = cx + startR * cos(angle);
      final startY = cy + startR * sin(angle);
      final endX = cx + endR * cos(angle);
      final endY = cy + endR * sin(angle);

      final barPaint = Paint()
        ..color = color.withOpacity(0.5 + barHeights[i] * 0.5)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), barPaint);
    }

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.2 + (sin(glowPhase) * 0.1).abs()),
          color.withOpacity(0.0),
        ],
      ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius * 1.5));
    canvas.drawCircle(Offset(cx, cy), radius * 1.5, glowPaint);
  }

  @override
  bool shouldRepaint(_CircularPainter oldDelegate) => true;
}
