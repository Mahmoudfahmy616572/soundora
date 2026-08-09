import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single spatial "room": a precise set of acoustic parameters.
///
/// [eq] holds gain (in decibels) for the device's 5-band equalizer
/// (Bass, Low-Mid, Mid, High-Mid, Treble). [loudness] is a target gain in dB
/// for the Android LoudnessEnhancer. [pitch] and [speed] are playback
/// multipliers; [volume] is the master gain.
class SpatialRoom {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final List<double> eq; // 5 bands, dB
  final double loudness; // dB
  final double pitch;
  final double speed;
  final double volume;

  const SpatialRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.eq,
    this.loudness = 0,
    this.pitch = 1.0,
    this.speed = 1.0,
    this.volume = 1.0,
  });
}

/// Precise, acoustically-reasoned room presets. EQ bands map to a device's
/// 5-band equalizer (roughly 60 / 230 / 910 / 3600 / 14000 Hz).
const List<SpatialRoom> kSpatialRooms = [
  SpatialRoom(
    id: 'immersive',
    name: 'Immersive',
    description: 'Balanced 3D stage with a gentle mid lift',
    icon: Icons.surround_sound,
    eq: [0, 0.5, 1.0, 0.5, 0],
  ),
  SpatialRoom(
    id: 'studio',
    name: 'Studio Monitor',
    description: 'Flat, neutral reference with no coloration',
    icon: Icons.headphones,
    eq: [0, 0, 0, 0, 0],
    volume: 0.85,
  ),
  SpatialRoom(
    id: 'concert',
    name: 'Concert Hall',
    description: 'Big space: rich lows, soft highs, natural decay',
    icon: Icons.stadium,
    eq: [2, 1, 0, 0.5, -1],
    pitch: 0.995,
    speed: 0.99,
  ),
  SpatialRoom(
    id: 'cathedral',
    name: 'Cathedral',
    description: 'Massive reverb, deep lows, airy ceiling',
    icon: Icons.church,
    eq: [4, 2, -1, -0.5, 1],
    loudness: 2,
    pitch: 0.98,
    speed: 0.97,
  ),
  SpatialRoom(
    id: 'intimate',
    name: 'Intimate',
    description: 'Warm and close, like a private bedroom',
    icon: Icons.hearing,
    eq: [1, 1, 2, 0.5, -1],
    pitch: 1.005,
    volume: 0.75,
  ),
  SpatialRoom(
    id: 'stage',
    name: 'Live Stage',
    description: 'Vocal-forward presence with stage depth',
    icon: Icons.mic,
    eq: [1, 0.5, 2, 1, 0],
    volume: 0.9,
  ),
  SpatialRoom(
    id: 'club',
    name: 'Club',
    description: 'Punchy bass and tight energy',
    icon: Icons.nightlife,
    eq: [5, 3, 0, 0, 1],
    loudness: 3,
    pitch: 1.01,
    speed: 1.02,
  ),
  SpatialRoom(
    id: 'reference',
    name: 'Reference',
    description: 'Tight neutral monitoring with clear treble',
    icon: Icons.graphic_eq,
    eq: [0, 0, 0, 0.5, 1],
    volume: 0.8,
  ),
  SpatialRoom(
    id: 'arena',
    name: 'Stadium',
    description: 'Huge arena: boosted lows and highs, scooped mids',
    icon: Icons.sports,
    eq: [3, 1, -2, 0, 2],
    loudness: 4,
    pitch: 0.99,
  ),
  SpatialRoom(
    id: 'booth',
    name: 'Vocal Booth',
    description: 'Dry, tight and ultra clear for vocals',
    icon: Icons.record_voice_over,
    eq: [-1, 0.5, 2, 1.5, 0.5],
    volume: 0.8,
  ),
  SpatialRoom(
    id: 'cave',
    name: 'Cave',
    description: 'Dark and boomy with a slow, heavy atmosphere',
    icon: Icons.terrain,
    eq: [3, 4, 1, -2, -3],
    pitch: 0.97,
    speed: 0.95,
    volume: 0.9,
  ),
  SpatialRoom(
    id: 'cinema',
    name: 'Cinema',
    description: 'Deep bass, clear dialogue, wide screen',
    icon: Icons.movie,
    eq: [4, 2, 1, 0.5, 0],
    loudness: 2,
  ),
  SpatialRoom(
    id: 'outdoor',
    name: 'Open Air',
    description: 'Light, airy and natural without room walls',
    icon: Icons.landscape,
    eq: [-2, -1, 0, 1, 2],
    volume: 0.85,
  ),
  SpatialRoom(
    id: 'vinyl',
    name: 'Lo-fi Vinyl',
    description: 'Warm, nostalgic with rolled-off highs',
    icon: Icons.album,
    eq: [2, 2, 1, 0, -2],
    pitch: 0.99,
    volume: 0.8,
  ),
  SpatialRoom(
    id: 'car',
    name: 'Car System',
    description: 'Punchy bass over road noise, smooth highs — the road-trip mix',
    icon: Icons.directions_car,
    eq: [5, 2.5, 0.5, 1.5, -0.5],
    loudness: 4,
    pitch: 1.0,
    speed: 1.0,
    volume: 0.95,
  ),
];

/// Owns the real DSP effects (Android equalizer + loudness enhancer) and
/// applies spatial settings to the [AudioPlayer]. The effects must be part of
/// the player's [AudioPipeline], so [buildPipeline] is called exactly once
/// before the player is created and the same effect instances are re-used.
class SpatialAudioEngine {
  SpatialAudioEngine._();

  static final SpatialAudioEngine instance = SpatialAudioEngine._();

  static bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  AndroidEqualizer? _equalizer;
  AndroidLoudnessEnhancer? _loudness;
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _stateSub;

  // ---- persisted settings ----
  bool _enabled = false;
  SpatialRoom _room = kSpatialRooms.first;
  double _intensity = 0.7;
  double _pitch = 1.0;
  List<double>? _customEq; // overrides the room curve when set

  bool get enabled => _enabled;
  SpatialRoom get room => _room;
  double get intensity => _intensity;
  double get pitch => _pitch;
  List<double>? get customEq => _customEq;

  /// Builds the [AudioPipeline] carrying the real effects (Android only).
  /// Must be called once, before the [AudioPlayer] is constructed.
  AudioPipeline buildPipeline() {
    if (_isAndroid) {
      _equalizer = AndroidEqualizer();
      _loudness = AndroidLoudnessEnhancer();
      return AudioPipeline(androidAudioEffects: [_equalizer!, _loudness!]);
    }
    return AudioPipeline();
  }

  /// Binds the engine to the app's [AudioPlayer] so settings can be applied
  /// and re-applied whenever a new source becomes ready.
  void attach(AudioPlayer player) {
    _player = player;
    _stateSub ??= player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.ready) {
        apply();
      }
    });
  }

  /// Applies the current spatial settings to the bound player. Safe to call
  /// repeatedly; while the player is disconnected the EQ gains are stored and
  /// restored automatically when it connects.
  Future<void> apply() async {
    final player = _player;
    if (player == null) return;

    if (!_enabled) {
      await player.setVolume(1.0);
      await player.setSpeed(1.0);
      try {
        await player.setPitch(1.0);
      } catch (_) {}
      await _equalizer?.setEnabled(false);
      await _loudness?.setEnabled(false);
      return;
    }

    await player.setVolume(_room.volume * (0.5 + 0.5 * _intensity));
    await player.setSpeed(_room.speed);
    try {
      await player.setPitch(_pitch * _room.pitch);
    } catch (_) {}

    final le = _loudness;
    if (le != null) {
      await le.setEnabled(true);
      await le.setTargetGain(_room.loudness * _intensity);
    }

    final eq = _equalizer;
    if (eq == null) return;
    await eq.setEnabled(true);
    try {
      final params = await eq.parameters.timeout(const Duration(seconds: 3));
      final bands = params.bands;
      final curve = _customEq ?? _room.eq;
      for (var i = 0; i < bands.length; i++) {
        final gain = curve.isEmpty ? 0.0 : curve[i % curve.length] * _intensity;
        final clamped = gain.clamp(params.minDecibels, params.maxDecibels);
        await bands[i].setGain(clamped);
      }
    } catch (_) {
      // Player not connected yet — gains are restored on connect.
    }
  }

  void setEnabled(bool value) {
    _enabled = value;
  }

  void setRoom(SpatialRoom room) {
    _room = room;
  }

  void setIntensity(double value) {
    _intensity = value;
  }

  void setPitch(double value) {
    _pitch = value;
  }

  void setCustomEq(List<double>? curve) {
    _customEq = curve;
  }

  /// Restores persisted settings and applies them to the bound player.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('spatial_enabled') ?? false;
    _intensity = prefs.getDouble('spatial_intensity') ?? 0.7;
    _pitch = prefs.getDouble('spatial_pitch') ?? 1.0;

    final roomId = prefs.getString('spatial_room');
    _room = kSpatialRooms.firstWhere(
      (r) => r.id == roomId,
      orElse: () => kSpatialRooms.first,
    );

    final eq = prefs.getString('spatial_custom_eq');
    if (eq != null && eq.isNotEmpty) {
      _customEq = eq
          .split(',')
          .map((s) => double.tryParse(s))
          .whereType<double>()
          .toList();
    } else {
      _customEq = null;
    }

    await apply();
  }

  /// Persists the current settings.
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('spatial_enabled', _enabled);
    await prefs.setString('spatial_room', _room.id);
    await prefs.setDouble('spatial_intensity', _intensity);
    await prefs.setDouble('spatial_pitch', _pitch);
    final eq = _customEq;
    await prefs.setString(
      'spatial_custom_eq',
      eq == null ? '' : eq.map((g) => g.toStringAsFixed(1)).join(','),
    );
  }
}
