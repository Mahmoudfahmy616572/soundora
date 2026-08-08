// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soundora/core/services/lyric_alignment.dart';
import 'package:soundora/data/sources/lyrics/lyrics_data_source.dart';

/// Heavy DSP (decode + FFT + VAD) runs off the main isolate to avoid ANRs.
class SyncAnalyzer {
  static const _channel = MethodChannel('audio_decoder');

  final Dio _dio;
  SyncAnalyzer(this._dio);

  Future<LyricAlignment?> analyze(
    String audioUrl,
    List<LyricLine> lyrics, {
    Map<String, String>? headers,
  }) async {
    if (lyrics.length < 3) return null;
    try {
      final tempDir = await getTemporaryDirectory();
      final wavFile = File('${tempDir.path}/sync_${DateTime.now().millisecondsSinceEpoch}.wav');

      File audioFile;
      final local = File(audioUrl);
      if (local.existsSync()) {
        // Offline playback: analyse the local file directly.
        audioFile = local;
      } else {
        audioFile =
            File('${tempDir.path}/sync_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await _dio.download(
          audioUrl,
          audioFile.path,
          options: Options(headers: headers),
        );
      }
      if (!audioFile.existsSync()) return null;

      try {
        await _channel.invokeMethod('decodeToWav', {
          'inputPath': audioFile.path,
          'outputPath': wavFile.path,
        });
      } on MissingPluginException {
        audioFile.deleteSync();
        return null;
      }

      if (!wavFile.existsSync()) {
        audioFile.deleteSync();
        return null;
      }

      // The actual DSP (read samples, onset detection, VAD, fitting) is CPU
      // heavy over the whole track â€” run it on a background isolate so the UI
      // thread never stalls.
      final wavPath = wavFile.path;
      final result = await Isolate.run<_SyncResult>(() {
        final wavBytes = File(wavPath).readAsBytesSync();
        // Use the sample rate actually stored in the WAV header: sources vary
        // (44.1/48 kHz, etc.) and hardcoding one would skew every time
        // estimate by a few percent â€” exactly the per-song drift seen before.
        final sampleRate = wavSampleRate(wavBytes);
        if (sampleRate <= 0) return const _SyncResult(null, 0);
        final samples = readWavSamples(wavBytes);
        if (samples.isEmpty) return const _SyncResult(null, 0);

        final onsets = detectOnsets(samples, sampleRate);
        if (onsets.length < 3) return _SyncResult(null, onsets.length);

        final alignment =
            alignToVocalWindow(lyrics, samples, sampleRate, onsets);
        return _SyncResult(alignment, onsets.length);
      });
      audioFile.deleteSync();
      wavFile.deleteSync();

      final alignment = result.alignment;
      if (alignment != null) {
        print('[SYNC] alignment: shift=${alignment.shiftMs}ms '
            'scale=${alignment.scale.toStringAsFixed(3)} '
            'onsets=${result.onsetsCount}');
      }
      return alignment;
    } catch (_) {
      return null;
    }
  }
}

class _SyncResult {
  final LyricAlignment? alignment;
  final int onsetsCount;
  const _SyncResult(this.alignment, this.onsetsCount);
}

/// Sample rate stored in the WAV header (bytes 24-27, PCM int32 little-endian).
/// The Android decoder writes the source file's own rate (44.1/48 kHz, etc.),
/// so every time computation must use this value, never a hardcoded one.
int wavSampleRate(Uint8List wavBytes) {
  if (wavBytes.length < 44) return 0;
  return ByteData.sublistView(wavBytes, 24, 28).getUint32(0, Endian.little);
}

/// Number of channels stored in the WAV header (bytes 22-23).
int wavChannelCount(Uint8List wavBytes) {
  if (wavBytes.length < 44) return 1;
  final channels =
      ByteData.sublistView(wavBytes, 22, 24).getUint16(0, Endian.little);
  return channels > 0 ? channels : 1;
}

/// Decodes a 16-bit PCM WAV into a mono [Float64List] of frames normalized to
/// [-1, 1], one entry per audio frame (multi-channel files are mixed to mono).
/// The frame index maps to time as `frame / sampleRate`, so callers MUST use
/// [wavSampleRate] (never a hardcoded rate) when converting to seconds.
Float64List readWavSamples(Uint8List wavBytes) {
  if (wavBytes.length < 44) return Float64List(0);
  final sampleRate = wavSampleRate(wavBytes);
  if (sampleRate == 0) return Float64List(0);
  final channels = wavChannelCount(wavBytes);
  final dataSize = ByteData.sublistView(wavBytes, 40, 44).getUint32(0, Endian.little);
  final frameCount = dataSize ~/ (2 * channels);
  final result = Float64List(frameCount);
  for (int f = 0; f < frameCount; f++) {
    final base = 44 + f * 2 * channels;
    if (base + 2 * channels > wavBytes.length) break;
    var sum = 0;
    for (int c = 0; c < channels; c++) {
      final offset = base + c * 2;
      sum += ByteData.sublistView(wavBytes, offset, offset + 2)
          .getInt16(0, Endian.little);
    }
    result[f] = (sum / channels) / 32768.0;
  }
  return result;
}

List<Duration> detectOnsets(Float64List samples, int sampleRate) {
  const frameSize = 1024;
  const hopSize = 512;
  final numFrames = (samples.length - frameSize) ~/ hopSize;
  if (numFrames < 1) return [];

  final energies = Float64List(numFrames);
  for (int i = 0; i < numFrames; i++) {
    final start = i * hopSize;
    double sum = 0;
    for (int j = 0; j < frameSize; j++) {
      if (start + j >= samples.length) break;
      sum += samples[start + j] * samples[start + j];
    }
    energies[i] = sqrt(sum / frameSize);
  }

  const smoothWindow = 4;
  final smoothed = Float64List(numFrames);
  for (int i = 0; i < numFrames; i++) {
    double s = 0;
    int count = 0;
    for (int j = -smoothWindow; j <= smoothWindow; j++) {
      final idx = i + j;
      if (idx >= 0 && idx < numFrames) {
        s += energies[idx];
        count++;
      }
    }
    smoothed[i] = s / count;
  }

  final novelty = Float64List(numFrames);
  for (int i = 1; i < numFrames; i++) {
    final diff = smoothed[i] - smoothed[i - 1];
    novelty[i] = diff > 0 ? diff : 0;
  }

  final onsets = <Duration>[];
  final halfWindow = 3;
  final threshold = _mean(novelty) * 1.5;
  for (int i = halfWindow; i < numFrames - halfWindow; i++) {
    if (novelty[i] < threshold) continue;
    bool isPeak = true;
    for (int j = -halfWindow; j <= halfWindow; j++) {
      if (j == 0) continue;
      if (novelty[i + j] >= novelty[i]) {
        isPeak = false;
        break;
      }
    }
    if (isPeak) {
      final timeMs = (i * hopSize * 1000) ~/ sampleRate;
      onsets.add(Duration(milliseconds: timeMs));
    }
  }
  return onsets;
}

/// Finds the constant time shift that best aligns the lyric line starts to the
/// detected onsets. Unlike the two-point window fit, every lyric line
/// contributes: an instrumental intro, an outro or applause at the end, or a
/// percussion groove cannot drag the whole alignment off because they only
/// affect a small part of the score. The best shift is the one that parks the
/// most lyric starts right next to an onset, with the closest matches winning.
LyricAlignment? alignByOnsetCorrelation(
    List<LyricLine> lyrics, List<Duration> onsets,
    {double? audioDurationMs}) {
  if (lyrics.length < 3 || onsets.length < 3) return null;

  final times = onsets.map((o) => o.inMilliseconds).toList()..sort();
  final lyricMs = lyrics.map((l) => l.startTime.inMilliseconds).toList();

  const matchWindowMs = 350;
  const stepMs = 250;
  const maxShiftMs = 40000;

  double scoreAt(int shift) {
    var matched = 0;
    var dist = 0.0;
    for (final t in lyricMs) {
      final target = t + shift;
      final idx = _lowerBound(times, target);
      var best = 1 << 30;
      for (final k in [idx - 1, idx]) {
        if (k >= 0 && k < times.length) {
          final d = (times[k] - target).abs();
          if (d < best) best = d;
        }
      }
      if (best <= matchWindowMs) {
        matched++;
        dist += best;
      }
    }
    // One matched line outweighs any distance gain so the count dominates,
    // while the distance term breaks ties between shifts that match the same
    // number of lines (e.g. a periodic beat where every phase matches some).
    return matched * 10000 - dist;
  }

  var bestShift = 0;
  var bestScore = -1.0e18;
  for (int s = -maxShiftMs; s <= maxShiftMs; s += stepMs) {
    final sc = scoreAt(s);
    if (sc > bestScore) {
      bestScore = sc;
      bestShift = s;
    }
  }

  final matchedLines = (bestScore / 10000).floor();
  // A correct alignment parks the vast majority of lyric starts next to a
  // vocal onset. If less than half the lines line up, the lyrics and the audio
  // are very likely not the same recording â€” refuse to shift instead of
  // corrupting otherwise-fine lyrics with a wrong offset.
  final required = max(3, (lyrics.length * 0.5).ceil());
  if (matchedLines < required) return null;

  // Refine the coarse peak at a fine resolution so the final shift is not
  // quantised to the search step.
  var fineShift = bestShift;
  var fineScore = bestScore;
  for (int s = bestShift - stepMs + 25; s <= bestShift + stepMs - 25; s += 25) {
    final sc = scoreAt(s);
    if (sc > fineScore) {
      fineScore = sc;
      fineShift = s;
    }
  }

  // A shift that pushes the first line before the audio starts (or the last
  // one past its end) matched a wrong stretch of the track â€” reject it.
  if (audioDurationMs != null) {
    final firstMapped = lyricMs.first + fineShift;
    final lastMapped = lyricMs.last + fineShift;
    if (firstMapped < -8000 || lastMapped > audioDurationMs + 8000) {
      return null;
    }
  }

  return LyricAlignment(shiftMs: fineShift.toDouble());
}

int _lowerBound(List<int> sorted, int target) {
  var lo = 0;
  var hi = sorted.length;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (sorted[mid] < target) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo;
}

/// Keeps only onsets whose immediate aftermath is harmonic (tonal) â€” i.e. the
/// singing voice â€” and drops broadband hits such as drums and cymbals. Voice
/// has a strongly periodic spectrum (flatness near 0), while percussion is
/// noise-like (flatness near 1). Aligning to the filtered onsets keeps the
/// correlation from latching onto the beat grid instead of the voice.
List<Duration> filterVoiceOnsets(
    Float64List samples, int sampleRate, List<Duration> onsets) {
  if (onsets.length < 3) return onsets;
  const frameSize = 2048;
  final voice = <Duration>[];
  for (final o in onsets) {
    // Look 30ms past the attack: the transient itself is broadband for both
    // voice and percussion; the sustained body after it separates the two.
    final start =
        (o.inMilliseconds / 1000 * sampleRate + 0.03 * sampleRate).round();
    if (start < 0 || start + frameSize > samples.length) continue;
    if (_spectralFlatness(samples, start, frameSize, sampleRate) < 0.6) {
      voice.add(o);
    }
  }
  // Never starve the caller: if the classifier dropped almost everything, the
  // source has no strong tonal content â€” keep the original onset list so the
  // alignment still has candidates to work with.
  if (voice.length < 3) return onsets;
  return voice;
}

/// Spectral flatness (geometric mean / arithmetic mean of the magnitude
/// spectrum) of a short Hann-windowed frame over the vocal band
/// (~100 Hz - 5 kHz).
double _spectralFlatness(
    Float64List samples, int start, int size, int sampleRate) {
  final re = Float64List(size);
  for (int i = 0; i < size; i++) {
    final w = 0.5 - 0.5 * cos(2 * pi * i / (size - 1));
    re[i] = samples[start + i] * w;
  }
  final im = Float64List(size);
  _fft(re, im);

  final half = size ~/ 2;
  final loBin = (100 * size / sampleRate).floor().clamp(1, half - 1);
  final hiBin = (5000 * size / sampleRate).floor().clamp(loBin + 1, half - 1);
  var sumMag = 0.0;
  var sumLog = 0.0;
  for (int i = loBin; i <= hiBin; i++) {
    final mag = sqrt(re[i] * re[i] + im[i] * im[i]) + 1e-9;
    sumMag += mag;
    sumLog += log(mag);
  }
  final count = (hiBin - loBin + 1).toDouble();
  return exp(sumLog / count) / (sumMag / count);
}

/// In-place iterative radix-2 FFT on a power-of-two length.
void _fft(Float64List re, Float64List im) {
  final n = re.length;
  for (int i = 1, j = 0; i < n; i++) {
    var bit = n >> 1;
    while (j & bit != 0) {
      j ^= bit;
      bit >>= 1;
    }
    j ^= bit;
    if (i < j) {
      final tr = re[i];
      re[i] = re[j];
      re[j] = tr;
      final ti = im[i];
      im[i] = im[j];
      im[j] = ti;
    }
  }
  for (var len = 2; len <= n; len <<= 1) {
    final ang = -2 * pi / len;
    final wRe = cos(ang);
    final wIm = sin(ang);
    final half = len >> 1;
    for (var i = 0; i < n; i += len) {
      var curRe = 1.0;
      var curIm = 0.0;
      for (var j = 0; j < half; j++) {
        final uRe = re[i + j];
        final uIm = im[i + j];
        final vRe = re[i + j + half] * curRe - im[i + j + half] * curIm;
        final vIm = re[i + j + half] * curIm + im[i + j + half] * curRe;
        re[i + j] = uRe + vRe;
        im[i + j] = uIm + vIm;
        re[i + j + half] = uRe - vRe;
        im[i + j + half] = uIm - vIm;
        final nextRe = curRe * wRe - curIm * wIm;
        curIm = curRe * wIm + curIm * wRe;
        curRe = nextRe;
      }
    }
  }
}

/// Fits the provider lyric timestamps to the actual singing of the played
/// audio. The onset-correlation search is tried first, on the voice-filtered
/// onsets, because it is robust to instrument intros/outros and uses the whole
/// song; when it cannot find a confident shift, the window fit below is used
/// as a fallback (and only when that fit is trustworthy â€” a wrong offset is
/// worse than no offset).
///
/// The window fit is intentionally conservative:
///  * the scale is bounded to a few percent â€” different versions of a song run
///    at nearly the same tempo, so a scale far from 1.0 means the window
///    detection anchored to the wrong audio (e.g. a percussion intro), and the
///    only trustworthy correction left is a constant shift;
///  * when the implied tempo is basically identical, a shift-only alignment is
///    used so no artificial drift is injected into already-good lyrics;
///  * the result is validated against the audio timeline and rejected when it
///    would place lyrics outside it.
LyricAlignment? alignToVocalWindow(
    List<LyricLine> lyrics, Float64List samples, int sampleRate,
    List<Duration> onsets) {
  if (lyrics.length < 3) return null;

  final audioDurationMs = samples.length / sampleRate * 1000;

  // Align to the singing (harmonic) onsets, not to every hit of the drum kit.
  final voiceOnsets = filterVoiceOnsets(samples, sampleRate, onsets);
  final correlation = alignByOnsetCorrelation(lyrics, voiceOnsets,
      audioDurationMs: audioDurationMs);
  if (correlation != null) return correlation;

  // Fallback: fit the lyric span to the vocal window, preferring the
  // voice-filtered anchor (more accurate vocal entry), then the raw one.
  final voiceWindow = detectVocalWindow(samples, sampleRate, voiceOnsets);
  final fit = _fitWindow(lyrics, samples, audioDurationMs, voiceWindow);
  if (fit != null) return fit;

  final window = detectVocalWindow(samples, sampleRate, onsets);
  return _fitWindow(lyrics, samples, audioDurationMs, window);
}

LyricAlignment? _fitWindow(List<LyricLine> lyrics, Float64List samples,
    double audioEndMs, (int, int)? window) {
  if (window == null) return null;

  final lStart = lyrics.first.startTime.inMilliseconds;
  final prevStart =
      lyrics.length > 1 ? lyrics[lyrics.length - 2].startTime.inMilliseconds : 0;
  final lastStart = lyrics.last.startTime.inMilliseconds;
  final lEnd = lastStart + max(lastStart - prevStart, 1000);

  if (lEnd <= lStart) return null;
  final aStart = window.$1.toDouble();
  final aEnd = window.$2.toDouble();
  if (aEnd <= aStart) return null;

  const minScale = 0.97;
  const maxScale = 1.03;
  final scale = ((aEnd - aStart) / (lEnd - lStart)).clamp(minScale, maxScale);
  var shiftMs = aStart - scale * lStart;

  // Near-identical tempo: correct the offset only. This is the common case
  // (same recording, off-by-an-intro) and avoids stretching the lyrics.
  if ((scale - 1.0).abs() < 0.02) {
    shiftMs = aStart - lStart;
    // Keep scale = 1.0 exactly so the alignment never injects drift.
    return LyricAlignment(shiftMs: shiftMs.clamp(-600000.0, 600000.0));
  }

  // Sanity check: every mapped lyric must fall inside the audio timeline. A
  // fit that pushes the first line before the audio starts (or the last one
  // past its end) means the vocal window was detected on the wrong audio.
  final mappedStart = lStart * scale + shiftMs;
  final mappedEnd = lEnd * scale + shiftMs;
  if (mappedStart < -8000 || mappedEnd > audioEndMs + 8000) return null;

  return LyricAlignment(
    shiftMs: shiftMs.clamp(-600000.0, 600000.0),
    scale: scale.clamp(minScale, maxScale),
  );
}

/// Energy-based VAD over the whole track: finds the first and last "loud,
/// sustained" frames and returns their times in ms. The start is refined by
/// [detectVocalEntry] so a loud instrumental intro does not stretch the
/// window backwards.
(int, int)? detectVocalWindow(
    Float64List samples, int sampleRate, List<Duration> onsets) {
  const frameSize = 1024;
  const hopSize = 256;
  final numFrames = (samples.length - frameSize) ~/ hopSize;
  if (numFrames < 8) return null;

  final energies = Float64List(numFrames);
  for (int i = 0; i < numFrames; i++) {
    final start = i * hopSize;
    double sum = 0;
    for (int j = 0; j < frameSize; j++) {
      if (start + j >= samples.length) break;
      final s = samples[start + j];
      sum += s * s;
    }
    energies[i] = sqrt(sum / frameSize);
  }

  final sorted = Float64List.fromList(energies)..sort();
  final p15 = sorted[(sorted.length * 0.15).floor()];
  final p85 = sorted[(sorted.length * 0.85).floor()];
  final thr = p15 + 0.35 * (p85 - p15);

  final active = List<bool>.filled(numFrames, false);
  for (int i = 0; i < numFrames; i++) {
    active[i] = energies[i] > thr;
  }

  const hangMs = 200;
  const gapMs = 500;
  final hangFrames = (hangMs * sampleRate / 1000 / hopSize).round();
  final gapFrames = (gapMs * sampleRate / 1000 / hopSize).round();

  final expanded = List<bool>.filled(numFrames, false);
  for (int i = 0; i < numFrames; i++) {
    if (!active[i]) continue;
    for (int j = i; j < min(numFrames, i + hangFrames); j++) {
      expanded[j] = true;
    }
  }

  var first = -1;
  var last = -1;
  for (int i = 0; i < numFrames; i++) {
    if (!expanded[i]) continue;
    if (first < 0) first = i;
    last = i;
  }
  if (first < 0 || last <= first) return null;

  // Merge short gaps between active runs so brief instrumental dips inside a
  // vocal phrase do not split the window.
  var gapStart = -1;
  for (int i = first; i <= last; i++) {
    if (expanded[i]) {
      if (gapStart >= 0) {
        final gapLen = i - gapStart;
        if (gapLen <= gapFrames) {
          for (int j = gapStart; j < i; j++) {
            expanded[j] = true;
          }
        }
        gapStart = -1;
      }
    } else if (gapStart < 0) {
      gapStart = i;
    }
  }

  int firstFinal = -1;
  int lastFinal = -1;
  for (int i = first; i <= last; i++) {
    if (!expanded[i]) continue;
    if (firstFinal < 0) firstFinal = i;
    lastFinal = i;
  }
  if (firstFinal < 0) return null;

  final entryMs = detectVocalEntry(onsets);
  final startMs = entryMs != null
      ? entryMs.inMilliseconds
      : firstFinal * hopSize * 1000 ~/ sampleRate;
  final endMs = lastFinal * hopSize * 1000 ~/ sampleRate;
  if (endMs <= startMs) return null;
  return (startMs, endMs);
}

/// Finds the moment the vocals enter: the first sustained run of dense
/// onsets. Instrumental intros (solo oud/takht) are usually sparse, while
/// singing produces a steady stream of syllable attacks. Anchoring the
/// lyric offset to this point avoids the trap of matching lyrics to musical
/// onsets (every beat) at some arbitrary offset.
Duration? detectVocalEntry(List<Duration> onsets) {
  if (onsets.length < 5) return null;
  const windowMs = 3000;
  const stepMs = 1000;
  const densityThreshold = 0.9; // onsets per second
  const minSustainedWindows = 3;

  final times = onsets.map((o) => o.inMilliseconds).toList();
  final tEnd = times.last;
  int i = 0;
  for (int t = 0; t + windowMs <= tEnd; t += stepMs) {
    while (i < times.length && times[i] < t) {
      i++;
    }
    int j = i;
    while (j < times.length && times[j] <= t + windowMs) {
      j++;
    }
    final density = (j - i) / (windowMs / 1000.0);
    if (density < densityThreshold) continue;

    var sustained = true;
    for (int k = 1; k < minSustainedWindows; k++) {
      final t2 = t + k * stepMs;
      if (t2 + windowMs > tEnd) break;
      // The windows overlap (stepMs < windowMs): recount the window from its
      // own start. Continuing j from the previous window's end would only see
      // the newly-added tail and underestimate the density ~3x.
      var i2 = 0;
      while (i2 < times.length && times[i2] < t2) {
        i2++;
      }
      var j3 = i2;
      while (j3 < times.length && times[j3] <= t2 + windowMs) {
        j3++;
      }
      final d2 = (j3 - i2) / (windowMs / 1000.0);
      if (d2 < densityThreshold) {
        sustained = false;
        break;
      }
    }
    if (sustained) {
      // Anchor to the first onset inside the qualifying window, not the
      // window's leading edge: the sliding 3s window starts up to 2s before
      // the singing actually begins, and using its edge would shift every
      // lyric line early by that amount.
      return Duration(milliseconds: times[i]);
    }
  }
  return null;
}

double _mean(Float64List data) {
  if (data.isEmpty) return 0;
  double s = 0;
  for (final v in data) {
    s += v;
  }
  return s / data.length;
}
