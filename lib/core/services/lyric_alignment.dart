/// Maps a provider lyric timestamp to the time in the actual audio being
/// played. A pure constant shift cannot align lyrics whose recording differs
/// from the provider's (different intro, tempo, or length), so alignment also
/// carries a scale factor: `t' = t * scale + shiftMs`.
class LyricAlignment {
  final double shiftMs;
  final double scale;

  const LyricAlignment({this.shiftMs = 0, this.scale = 1.0});

  static const identity = LyricAlignment();

  Duration effectiveTime(Duration lyricStart) => Duration(
        milliseconds: (lyricStart.inMilliseconds * scale + shiftMs).round(),
      );

  LyricAlignment nudged(int deltaMs) => LyricAlignment(
        shiftMs: shiftMs + deltaMs,
        scale: scale,
      );

  @override
  bool operator ==(Object other) =>
      other is LyricAlignment &&
      other.shiftMs == shiftMs &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(shiftMs, scale);

  @override
  String toString() => 'LyricAlignment(shiftMs: $shiftMs, scale: $scale)';
}
