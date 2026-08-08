import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundora/core/services/sync_analyzer.dart';
import 'package:soundora/data/sources/lyrics/lyrics_data_source.dart';

/// Synthesizes a 20s mono track: near-silent intro/outro with a loud "vocal"
/// segment (sine + onset clicks) between [vocalStartMs] and [vocalEndMs].
/// [clickTimes] lets tests place the syllable attacks exactly where the lyrics
/// claim them; by default a realistic irregular train (200-500ms gaps) is
/// generated so the track is not metronomically periodic.
Float64List _synthVocal(
  int sampleRate, {
  required int vocalStartMs,
  required int vocalEndMs,
  List<double>? clickTimes,
}) {
  final totalSamples = sampleRate * 20;
  final out = Float64List(totalSamples);

  final clicks = clickTimes ?? <double>[vocalStartMs.toDouble()];
  if (clickTimes == null) {
    final jitter = Random(7);
    var c = vocalStartMs.toDouble();
    while (c < vocalEndMs) {
      c += 200 + jitter.nextDouble() * 300;
      clicks.add(c);
    }
  }
  int clickIdx = 0;

  for (int i = 0; i < totalSamples; i++) {
    final tMs = i / sampleRate * 1000;
    final t = i / sampleRate;
    double v;
    if (tMs >= vocalStartMs && tMs < vocalEndMs) {
      final freq = 220 + 40 * sin(2 * pi * t / 4.0);
      v = 0.4 * sin(2 * pi * freq * t);
      while (clickIdx < clicks.length && clicks[clickIdx] + 100 < tMs) {
        clickIdx++;
      }
      if (clickIdx < clicks.length && tMs >= clicks[clickIdx]) {
        v += 0.3 * exp(-(tMs - clicks[clickIdx]) / 40.0);
      }
    } else {
      v = 0.004 * sin(2 * pi * 40 * t);
    }
    out[i] = v;
  }
  return out;
}

List<LyricLine> _lyricsFrom(List<int> msList) => msList
    .map((ms) => LyricLine('line', Duration(milliseconds: ms)))
    .toList();

Uint8List _buildWav(Float64List samples, int sampleRate) {
  final dataSize = samples.length * 2;
  final bytes = Uint8List(44 + dataSize);
  final bd = ByteData.view(bytes.buffer);
  bytes.setRange(0, 4, Uint8List.fromList('RIFF'.codeUnits));
  bd.setUint32(4, 36 + dataSize, Endian.little);
  bytes.setRange(8, 12, Uint8List.fromList('WAVE'.codeUnits));
  bytes.setRange(12, 16, Uint8List.fromList('fmt '.codeUnits));
  bd.setUint32(16, 16, Endian.little);
  bd.setUint16(20, 1, Endian.little); // PCM
  bd.setUint16(22, 1, Endian.little); // mono
  bd.setUint32(24, sampleRate, Endian.little);
  bd.setUint32(28, sampleRate * 2, Endian.little);
  bd.setUint16(32, 2, Endian.little);
  bd.setUint16(34, 16, Endian.little);
  bytes.setRange(36, 40, Uint8List.fromList('data'.codeUnits));
  bd.setUint32(40, dataSize, Endian.little);
  for (int i = 0; i < samples.length; i++) {
    final s = (samples[i] * 32767).round().clamp(-32768, 32767);
    bd.setInt16(44 + i * 2, s, Endian.little);
  }
  return bytes;
}

void main() {
  const sampleRate = 8000;

  group('detectVocalEntry', () {
    test('anchors to the first vocal onset, not the window edge', () {
      final samples = _synthVocal(sampleRate,
          vocalStartMs: 4000, vocalEndMs: 16000);
      final onsets = detectOnsets(samples, sampleRate);
      final entry = detectVocalEntry(onsets);
      expect(entry, isNotNull);
      expect(entry!.inMilliseconds, greaterThanOrEqualTo(3500));
      expect(entry.inMilliseconds, lessThanOrEqualTo(5500));
    });
  });

  group('detectVocalWindow', () {
    test('finds the vocal span for a clean track', () {
      final samples = _synthVocal(sampleRate,
          vocalStartMs: 4000, vocalEndMs: 16000);
      final onsets = detectOnsets(samples, sampleRate);
      final window = detectVocalWindow(samples, sampleRate, onsets);
      expect(window, isNotNull);
      expect(window!.$1, greaterThanOrEqualTo(3500));
      expect(window.$1, lessThanOrEqualTo(5500));
      expect(window.$2, greaterThanOrEqualTo(15000));
      expect(window.$2, lessThanOrEqualTo(17000));
    });
  });

  group('filterVoiceOnsets', () {
    test('keeps harmonic (voice) onsets and drops broadband (percussion)', () {
      const sr = 8000;
      final samples = Float64List(sr * 2); // 2s
      final rng = Random(3);
      for (int i = 0; i < samples.length; i++) {
        final tMs = i / sr * 1000;
        if (tMs < 1100) {
          samples[i] = 0.5 * sin(2 * pi * 400 * i / sr);
        } else {
          samples[i] = (rng.nextDouble() - 0.5) * 0.6;
        }
      }
      final voice = [100, 200, 300, 400, 500, 600, 700, 800]
          .map((m) => Duration(milliseconds: m))
          .toList();
      final drums = [1300, 1400, 1500]
          .map((m) => Duration(milliseconds: m))
          .toList();
      final filtered = filterVoiceOnsets(samples, sr, [...voice, ...drums]);
      final kept = filtered.map((o) => o.inMilliseconds).toSet();
      for (final m in [100, 200, 300, 400, 500, 600, 700, 800]) {
        expect(kept, contains(m));
      }
      for (final m in [1300, 1400, 1500]) {
        expect(kept, isNot(contains(m)));
      }
    });

    test('never starves the caller when nothing is tonal', () {
      const sr = 8000;
      final samples = Float64List(sr * 2);
      final rng = Random(9);
      for (int i = 0; i < samples.length; i++) {
        samples[i] = (rng.nextDouble() - 0.5) * 0.6;
      }
      final onsets = [100, 200, 300, 400, 500]
          .map((m) => Duration(milliseconds: m))
          .toList();
      final filtered = filterVoiceOnsets(samples, sr, onsets);
      // Noise-only track: every onset is dropped, so the original list is kept.
      expect(filtered.length, onsets.length);
    });
  });

  group('alignByOnsetCorrelation', () {
    List<Duration> atMs(List<int> ms) =>
        ms.map((m) => Duration(milliseconds: m)).toList();

    test('finds the true constant offset', () {
      final lyrics = _lyricsFrom([4000, 6000, 8000, 10000, 12000, 14000]);
      // Vocals sing 2.5s after the lyric timestamps claim.
      final onsets = atMs([6500, 8500, 10500, 12500, 14500, 16500]);
      final alignment =
          alignByOnsetCorrelation(lyrics, onsets, audioDurationMs: 20000);
      expect(alignment, isNotNull);
      expect(alignment!.scale, 1.0);
      expect(alignment.shiftMs, closeTo(2500, 300));
    });

    test('is not thrown off by a dense instrumental intro', () {
      final lyrics = _lyricsFrom([4000, 6000, 8000, 10000, 12000, 14000]);
      // A busy percussion intro before the singing, plus the singing onsets.
      final intro =
          List.generate(15, (i) => Duration(milliseconds: 200 * i));
      final vocals = atMs([6500, 8500, 10500, 12500, 14500, 16500]);
      final alignment = alignByOnsetCorrelation(lyrics, [...intro, ...vocals],
          audioDurationMs: 20000);
      expect(alignment, isNotNull);
      expect(alignment!.shiftMs, closeTo(2500, 300));
    });

    test('rejects too few onsets', () {
      final lyrics = _lyricsFrom([4000, 6000, 8000]);
      expect(alignByOnsetCorrelation(lyrics, atMs([5000, 6000]),
          audioDurationMs: 20000),
          isNull);
    });

    test('rejects lyrics that never line up with any onsets', () {
      // Each lyric time needs a different shift to reach the onsets, so no
      // single shift can match even three lines.
      final lyrics = _lyricsFrom([0, 30000, 60000]);
      final onsets =
          List.generate(30, (i) => Duration(milliseconds: 4000 + i * 400));
      expect(alignByOnsetCorrelation(lyrics, onsets,
          audioDurationMs: 20000), isNull);
    });
  });

  group('alignToVocalWindow', () {
    test('well-matched lyrics get a near-identity shift-only fit', () {
      const lyricMs = [4000, 6000, 8000, 10000, 12000, 14000];
      final samples = _synthVocal(sampleRate,
          vocalStartMs: 4000,
          vocalEndMs: 16000,
          clickTimes: lyricMs.map((m) => m.toDouble()).toList());
      final onsets = detectOnsets(samples, sampleRate);
      final lyrics = _lyricsFrom(lyricMs);
      final alignment = alignToVocalWindow(lyrics, samples, sampleRate, onsets);
      expect(alignment, isNotNull);
      // Same tempo -> the fit must stay shift-only (scale exactly 1.0).
      expect(alignment!.scale, 1.0);
      expect(alignment.shiftMs.abs(), lessThan(400));
    });

    test('scale is bounded and never stretches lyrics wildly', () {
      // Clicks clustered far from the (packed) lyrics so the correlation finds
      // no confident shift and the conservative window-fit clamp is exercised.
      final samples = _synthVocal(sampleRate,
          vocalStartMs: 4000,
          vocalEndMs: 16000,
          clickTimes: const [10000, 10200, 10400, 10600, 10800]);
      final onsets = detectOnsets(samples, sampleRate);
      // Lyrics packed into half the vocal window -> implied scale ~2, clamped.
      final lyrics = _lyricsFrom([4000, 5000, 6000, 7000, 8000]);
      final alignment = alignToVocalWindow(lyrics, samples, sampleRate, onsets);
      expect(alignment, isNotNull);
      expect(alignment!.scale, lessThanOrEqualTo(1.03));
      expect(alignment.scale, greaterThanOrEqualTo(0.97));
    });

    test('impossibly long lyrics are rejected (no alignment)', () {
      final samples = _synthVocal(sampleRate,
          vocalStartMs: 4000, vocalEndMs: 16000);
      final onsets = detectOnsets(samples, sampleRate);
      final lyrics = _lyricsFrom([0, 30000, 60000]);
      expect(
          alignToVocalWindow(lyrics, samples, sampleRate, onsets), isNull);
    });

    test('too few lines return null', () {
      final samples = _synthVocal(sampleRate,
          vocalStartMs: 4000, vocalEndMs: 16000);
      final onsets = detectOnsets(samples, sampleRate);
      expect(
          alignToVocalWindow(_lyricsFrom([4000, 5000]), samples, sampleRate,
              onsets),
          isNull);
    });
  });

  group('readWavSamples', () {
    test('round-trips 16-bit PCM mono', () {
      final original = _synthVocal(sampleRate,
          vocalStartMs: 4000, vocalEndMs: 16000);
      final wav = _buildWav(original, sampleRate);
      final decoded = readWavSamples(wav);
      expect(decoded.length, original.length);
      for (int i = 0; i < decoded.length; i += 997) {
        expect((decoded[i] - original[i]).abs(), lessThan(0.02));
      }
    });

    test('wavSampleRate reads the header value', () {
      final wav = _buildWav(
          _synthVocal(sampleRate, vocalStartMs: 4000, vocalEndMs: 16000),
          sampleRate);
      expect(wavSampleRate(wav), sampleRate);
    });

    test('stereo WAVs are mixed to mono frames (no doubled time)', () {
      const total = 1000;
      const channels = 2;
      final dataSize = total * channels * 2;
      final bytes = Uint8List(44 + dataSize);
      final bd = ByteData.view(bytes.buffer);
      bytes.setRange(0, 4, Uint8List.fromList('RIFF'.codeUnits));
      bd.setUint32(4, 36 + dataSize, Endian.little);
      bytes.setRange(8, 12, Uint8List.fromList('WAVE'.codeUnits));
      bytes.setRange(12, 16, Uint8List.fromList('fmt '.codeUnits));
      bd.setUint32(16, 16, Endian.little);
      bd.setUint16(20, 1, Endian.little);
      bd.setUint16(22, channels, Endian.little);
      bd.setUint32(24, 44100, Endian.little);
      bd.setUint32(28, 44100 * channels * 2, Endian.little);
      bd.setUint16(32, channels * 2, Endian.little);
      bd.setUint16(34, 16, Endian.little);
      bytes.setRange(36, 40, Uint8List.fromList('data'.codeUnits));
      bd.setUint32(40, dataSize, Endian.little);
      for (int f = 0; f < total; f++) {
        bd.setInt16(44 + f * 4, (0.25 * 32767).round(), Endian.little);
        bd.setInt16(44 + f * 4 + 2, (0.75 * 32767).round(), Endian.little);
      }
      expect(wavChannelCount(bytes), channels);
      expect(wavSampleRate(bytes), 44100);
      final samples = readWavSamples(bytes);
      expect(samples.length, total);
      expect((samples.first - 0.5).abs(), lessThan(0.01));
    });
  });
}
