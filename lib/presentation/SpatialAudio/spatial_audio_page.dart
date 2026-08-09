import 'dart:math' show sin, cos;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/presentation/SpatialAudio/spatial_audio_engine.dart';

class SpatialAudioPage extends StatefulWidget {
  const SpatialAudioPage({super.key});

  @override
  State<SpatialAudioPage> createState() => _SpatialAudioPageState();
}

class _SpatialAudioPageState extends State<SpatialAudioPage>
    with TickerProviderStateMixin {
  final SpatialAudioEngine _engine = SpatialAudioEngine.instance;

  late AnimationController _rotateController;
  late AnimationController _pulseController;

  // Local UI mirror of the engine settings.
  bool _enabled = false;
  SpatialRoom _room = kSpatialRooms.first;
  double _intensity = 0.7;
  double _pitch = 1.0;
  List<double> _eqCurve = List.of(kSpatialRooms.first.eq);
  bool _eqCustom = false;

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

  /// Pushes the current UI state into the engine, applies it to the live
  /// audio player and persists it.
  Future<void> _push({
    bool? enabled,
    SpatialRoom? room,
    double? intensity,
    double? pitch,
    List<double>? eq,
    bool? eqCustom,
  }) async {
    _engine.setEnabled(enabled ?? _enabled);
    _engine.setRoom(room ?? _room);
    _engine.setIntensity(intensity ?? _intensity);
    _engine.setPitch(pitch ?? _pitch);
    _engine.setCustomEq(eqCustom == true ? (eq ?? _room.eq) : null);
    await _engine.apply();
    await _engine.save();
  }

  Future<void> _restoreSettings() async {
    await _engine.restore();
    if (!mounted) return;
    setState(() {
      _enabled = _engine.enabled;
      _room = _engine.room;
      _intensity = _engine.intensity;
      _pitch = _engine.pitch;
      _eqCurve = List.of(_engine.customEq ?? _room.eq);
      _eqCustom = _engine.customEq != null;
    });
  }

  void _selectRoom(SpatialRoom room) {
    setState(() {
      _room = room;
      _eqCustom = false;
      _eqCurve = List.of(room.eq);
    });
    _push(room: room, eq: room.eq, eqCustom: false);
  }

  void _onEqBandChanged(int index, double value) {
    setState(() {
      _eqCurve[index] = value;
      _eqCustom = true;
    });
    _push(eq: _eqCurve, eqCustom: true);
  }

  void _resetEq() {
    setState(() {
      _eqCustom = false;
      _eqCurve = List.of(_room.eq);
    });
    _push(eq: _room.eq, eqCustom: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_enabled && !_rotateController.isAnimating) {
      _rotateController.repeat();
    } else if (!_enabled && _rotateController.isAnimating) {
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
            _buildRoomSection(),
            SizedBox(height: 24.h),
            _buildIntensitySlider(),
            SizedBox(height: 24.h),
            _buildPitchSlider(),
            SizedBox(height: 24.h),
            _buildEqSection(),
            SizedBox(height: 20.h),
            _buildInfoCard(),
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
          color: _enabled
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
                    enabled: _enabled,
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
                scale: _enabled ? 0.95 + _pulseController.value * 0.1 : 1.0,
                child: Container(
                  width: 70.w,
                  height: 70.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _enabled ? AppColors.primaryColor : Colors.grey[700],
                    boxShadow: _enabled
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
                    _room.icon,
                    color: Colors.white,
                    size: 32.sp,
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 20.w,
            child: _buildSpeakerDot('L', _enabled),
          ),
          Positioned(
            bottom: 20.w,
            child: _buildSpeakerDot('R', _enabled),
          ),
          Positioned(
            left: 20.w,
            child: _buildSpeakerDot('LS', _enabled),
          ),
          Positioned(
            right: 20.w,
            child: _buildSpeakerDot('RS', _enabled),
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
            value: _enabled,
            onChanged: (val) {
              setState(() => _enabled = val);
              _push(enabled: val);
            },
            activeColor: AppColors.primaryColor,
            activeTrackColor: AppColors.primaryColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sound Rooms (${kSpatialRooms.length})',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Choose your acoustic space — real DSP per room',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: kSpatialRooms.map(_buildRoomChip).toList(),
        ),
      ],
    );
  }

  Widget _buildRoomChip(SpatialRoom room) {
    final selected = _room.id == room.id;
    return GestureDetector(
      onTap: () => _selectRoom(room),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: selected
              ? AppColors.primaryColor.withOpacity(0.15)
              : Colors.grey[900],
          border: Border.all(
            color: selected ? AppColors.primaryColor : Colors.grey[800]!,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(room.icon, color: selected ? AppColors.primaryColor : Colors.grey, size: 16.sp),
            SizedBox(width: 6.w),
            Text(
              room.name,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
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
              onChanged: _enabled
                  ? (val) {
                      setState(() => _intensity = val);
                      _push(intensity: val);
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

  Widget _buildPitchSlider() {
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
                'Pitch',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${_pitch.toStringAsFixed(2)}x',
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
              value: _pitch,
              onChanged: _enabled
                  ? (val) {
                      setState(() => _pitch = val);
                      _push(pitch: val);
                    }
                  : null,
              min: 0.9,
              max: 1.1,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0.90x', style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
              Text('1.10x', style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEqSection() {
    const labels = ['Bass', 'Low-Mid', 'Mid', 'High-Mid', 'Treble'];
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
                '5-Band EQ',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (_eqCustom)
                GestureDetector(
                  onTap: _enabled ? _resetEq : null,
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Fine-tune each band in dB. Matches the ${_room.name} room curve by default.',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey),
          ),
          SizedBox(height: 8.h),
          for (var i = 0; i < labels.length; i++)
            _buildEqRow(i, labels[i]),
        ],
      ),
    );
  }

  Widget _buildEqRow(int index, String label) {
    final value = (_eqCurve.length > index ? _eqCurve[index] : 0.0)
        .clamp(-12.0, 12.0);
    return Row(
      children: [
        SizedBox(
          width: 64.w,
          child: Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: Colors.white70),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primaryColor,
              inactiveTrackColor: Colors.grey[800],
              thumbColor: AppColors.primaryColor,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              trackHeight: 2.5.h,
            ),
            child: Slider(
              value: value,
              onChanged: _enabled
                  ? (v) => _onEqBandChanged(index, v)
                  : null,
              min: -12.0,
              max: 12.0,
              divisions: 48,
            ),
          ),
        ),
        SizedBox(
          width: 48.w,
          child: Text(
            '${value.toStringAsFixed(1)} dB',
            textAlign: TextAlign.end,
            style: TextStyle(fontSize: 11.sp, color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.primaryColor, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Spatial audio uses the real Android DSP equalizer and loudness '
              'enhancer. On desktop or web, volume, speed and pitch still apply.',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey, height: 1.4),
            ),
          ),
        ],
      ),
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
