import 'dart:math' show sin, cos;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';

class SpatialAudioPage extends StatefulWidget {
  const SpatialAudioPage({super.key});

  @override
  State<SpatialAudioPage> createState() => _SpatialAudioPageState();
}

class _SpatialAudioPageState extends State<SpatialAudioPage>
    with TickerProviderStateMixin {
  bool _spatialEnabled = false;
  double _intensity = 0.7;
  String _selectedPreset = 'Immersive';
  late AnimationController _rotateController;
  late AnimationController _pulseController;

  final List<Map<String, dynamic>> _presets = [
    {
      'name': 'Immersive',
      'icon': Icons.surround_sound,
      'description': 'Full volume, natural tempo',
      'volume': 1.0,
      'speed': 1.0,
    },
    {
      'name': 'Concert Hall',
      'icon': Icons.stadium,
      'description': 'Slightly slower, deeper tone',
      'volume': 1.0,
      'speed': 0.95,
    },
    {
      'name': 'Studio',
      'icon': Icons.headphones,
      'description': 'Clean monitoring, lower gain',
      'volume': 0.85,
      'speed': 1.0,
    },
    {
      'name': 'Intimate',
      'icon': Icons.hearing,
      'description': 'Softer, brighter and closer',
      'volume': 0.7,
      'speed': 1.05,
    },
  ];

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _restoreSettings();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Applies the chosen effect to the real audio player. Every preset maps to
  /// an audible just_audio setting (volume gain + tempo), and the intensity
  /// slider scales the gain, so toggling it genuinely changes the sound.
  void _applyAudioSettings(AudioPlayer player) {
    if (_spatialEnabled) {
      final preset =
          _presets.firstWhere((p) => p['name'] == _selectedPreset);
      final baseVolume = (preset['volume'] as num).toDouble();
      final baseSpeed = (preset['speed'] as num).toDouble();
      player.setVolume(baseVolume * (0.5 + 0.5 * _intensity));
      player.setSpeed(baseSpeed);
    } else {
      player.setVolume(1.0);
      player.setSpeed(1.0);
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('spatial_enabled', _spatialEnabled);
    await prefs.setDouble('spatial_intensity', _intensity);
    await prefs.setString('spatial_preset', _selectedPreset);
  }

  Future<void> _restoreSettings() async {
    final player = context.read<SongPlayerCubit>().audioPlayer;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _spatialEnabled = prefs.getBool('spatial_enabled') ?? false;
    _intensity = prefs.getDouble('spatial_intensity') ?? 0.7;
    final preset = prefs.getString('spatial_preset');
    if (preset != null && _presets.any((p) => p['name'] == preset)) {
      _selectedPreset = preset;
    }
    _applyAudioSettings(player);
  }

  @override
  Widget build(BuildContext context) {
    if (_spatialEnabled && !_rotateController.isAnimating) {
      _rotateController.repeat();
    } else if (!_spatialEnabled && _rotateController.isAnimating) {
      _rotateController.stop();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Spatial Audio',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            _buildVisualization(),
            SizedBox(height: 28.h),
            _buildToggle(),
            SizedBox(height: 24.h),
            _buildIntensitySlider(),
            SizedBox(height: 28.h),
            _buildPresets(),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualization() {
    return Container(
      width: 280.w,
      height: 280.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[900],
        border: Border.all(
          color: _spatialEnabled
              ? AppColors.primaryColor.withOpacity(0.5)
              : Colors.grey[800]!,
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateController.value * 2 * 3.14159,
                child: CustomPaint(
                  size: Size(260.w, 260.w),
                  painter: _SpatialRingsPainter(
                    enabled: _spatialEnabled,
                    intensity: _intensity,
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _spatialEnabled
                    ? 0.95 + _pulseController.value * 0.1
                    : 1.0,
                child: Container(
                  width: 70.w,
                  height: 70.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _spatialEnabled
                        ? AppColors.primaryColor
                        : Colors.grey[700],
                    boxShadow: _spatialEnabled
                        ? [
                            BoxShadow(
                              color: AppColors.primaryColor
                                  .withOpacity(0.4 + _pulseController.value * 0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    Icons.headphones,
                    color: Colors.white,
                    size: 32.sp,
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 20.w,
            child: _buildSpeakerDot('L', _spatialEnabled),
          ),
          Positioned(
            bottom: 20.w,
            child: _buildSpeakerDot('R', _spatialEnabled),
          ),
          Positioned(
            left: 20.w,
            child: _buildSpeakerDot('LS', _spatialEnabled),
          ),
          Positioned(
            right: 20.w,
            child: _buildSpeakerDot('RS', _spatialEnabled),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakerDot(String label, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 36.w,
      height: 36.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? AppColors.primaryColor.withOpacity(0.3)
            : Colors.grey[800],
        border: Border.all(
          color: active ? AppColors.primaryColor : Colors.grey[700]!,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.sp,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '3D Audio',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Enable spatial sound processing',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Switch(
            value: _spatialEnabled,
            onChanged: (val) {
              setState(() => _spatialEnabled = val);
              _applyAudioSettings(
                  context.read<SongPlayerCubit>().audioPlayer);
              _saveSettings();
            },
            activeColor: AppColors.primaryColor,
            activeTrackColor: AppColors.primaryColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensitySlider() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Intensity',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${(_intensity * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primaryColor,
              inactiveTrackColor: Colors.grey[800],
              thumbColor: AppColors.primaryColor,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 3.h,
            ),
            child: Slider(
              value: _intensity,
              onChanged: _spatialEnabled
                  ? (val) {
                      setState(() => _intensity = val);
                      _applyAudioSettings(
                          context.read<SongPlayerCubit>().audioPlayer);
                      _saveSettings();
                    }
                  : null,
              min: 0.0,
              max: 1.0,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtle', style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
              Text('Maximum', style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Presets',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12.h),
        ...(_presets.map((preset) {
          final isSelected = _selectedPreset == preset['name'];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedPreset = preset['name']);
              _applyAudioSettings(context.read<SongPlayerCubit>().audioPlayer);
              _saveSettings();
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryColor.withOpacity(0.15)
                    : Colors.grey[900],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : Colors.grey[800]!,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    preset['icon'] as IconData,
                    color: isSelected ? AppColors.primaryColor : Colors.grey,
                    size: 24.sp,
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preset['name'] as String,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          preset['description'] as String,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle,
                        color: AppColors.primaryColor, size: 22.sp),
                ],
              ),
            ),
          );
        })),
      ],
    );
  }
}

class _SpatialRingsPainter extends CustomPainter {
  final bool enabled;
  final double intensity;

  _SpatialRingsPainter({required this.enabled, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      final radius = (size.width / 2) * (i / 5);
      paint.color = enabled
          ? AppColors.primaryColor.withOpacity((0.3 - i * 0.06) * intensity)
          : Colors.grey[800]!.withOpacity(0.2);
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }

    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 12; i++) {
      final angle = (2 * 3.14159 / 12) * i;
      final r = size.width * 0.42;
      final dx = cx + r * cos(angle);
      final dy = cy + r * sin(angle);
      dotPaint.color = enabled
          ? AppColors.primaryColor.withOpacity(0.5 * intensity)
          : Colors.grey[700]!.withOpacity(0.3);
      canvas.drawCircle(Offset(dx, dy), 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_SpatialRingsPainter oldDelegate) =>
      oldDelegate.enabled != enabled || oldDelegate.intensity != intensity;
}
