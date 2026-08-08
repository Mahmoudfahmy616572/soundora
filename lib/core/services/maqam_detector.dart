import 'dart:math' as math;
import 'dart:typed_data';

/// Runs a fresh detector inside a background isolate (the class is stateless).
MaqamResult? detectMaqamOnBackground(Float64List samples, int sourceSampleRate) {
  return MaqamDetector().detect(samples, sourceSampleRate);
}

class MaqamResult {
  final String arabicName;
  final String englishName;
  final String tonicName;
  final double confidence;
  const MaqamResult({
    required this.arabicName,
    required this.englishName,
    required this.tonicName,
    required this.confidence,
  });
}

class MaqamDetector {
  static const int _targetSampleRate = 8000;
  static const int _chromaBins = 24; // quarter-tone resolution (24-EDO)

  // Maqam scales as pitch-class sets in 24-EDO quarter-tone units (octave = 24).
  // Intervals follow the jins structure from Arabic maqam theory:
  //   Rast    [1, 3/4, 3/4]   Bayati [3/4, 3/4, 1]   Sikah  [3/4, 1]
  //   Hijaz   [1/2, 1.5, 1/2] Saba   [3/4, 3/4, 1/2] Nahawand = natural minor
  //   Ajam    = major          Kurd   = phrygian
  static const Map<String, Set<int>> _maqamTemplates = {
    'راست|Rast': {0, 4, 7, 10, 14, 18, 21},
    'نهاوند|Nahawand': {0, 4, 6, 10, 14, 16, 20},
    'عجم|Ajam': {0, 4, 8, 10, 14, 18, 22},
    'حجاز|Hijaz': {0, 2, 8, 10, 14, 16, 20},
    'صبا|Saba': {0, 3, 6, 8, 14, 16, 20},
    'كرد|Kurd': {0, 2, 6, 10, 14, 16, 20},
    'سيكاه|Sikah': {0, 3, 7, 10, 14, 17, 21},
    'بياتي|Bayati': {0, 3, 6, 10, 14, 16, 20},
  };

  static const List<String> _tonicNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  MaqamResult? detect(Float64List samples, int sourceSampleRate) {
    if (samples.length < 4096 || sourceSampleRate <= 0) return null;

    final chroma = _computeQuarterToneChroma(samples, sourceSampleRate);
    if (chroma == null) return null;

    double bestScore = -2;
    String bestMaqam = _maqamTemplates.keys.first;
    int bestTonic = 0;

    for (final entry in _maqamTemplates.entries) {
      for (int tonic = 0; tonic < _chromaBins; tonic++) {
        final score = _correlation(chroma, entry.value, tonic);
        if (score > bestScore) {
          bestScore = score;
          bestMaqam = entry.key;
          bestTonic = tonic;
        }
      }
    }

    if (bestScore < 0.08) return null;

    final parts = bestMaqam.split('|');
    return MaqamResult(
      arabicName: parts[0],
      englishName: parts[1],
      tonicName: _tonicNames[bestTonic ~/ 2],
      confidence: bestScore.clamp(0.0, 1.0),
    );
  }

  /// Downsample to ~8k mono, then build a 24-bin (quarter-tone) chroma
  /// averaged over the track. Per-frame chroma is energy-normalized so loud
  /// percussive/noisy frames do not dominate the average.
  Float64List? _computeQuarterToneChroma(
      Float64List samples, int sourceSampleRate) {
    final step = (sourceSampleRate / _targetSampleRate).round();
    if (step < 1) return null;
    final effectiveRate = sourceSampleRate / step;

    final downsampled = <double>[];
    for (int i = 0; i < samples.length; i += step) {
      downsampled.add(samples[i]);
    }
    if (downsampled.length < 4096) return null;

    const frameSize = 4096;
    const hop = 2048;
    final chroma = Float64List(_chromaBins);
    int frameCount = 0;

    // Bound the number of analyzed frames to keep latency reasonable.
    const maxFrames = 120;
    final totalFrames = (downsampled.length - frameSize) ~/ hop + 1;
    final frameStride = (totalFrames / maxFrames).ceil().clamp(1, 1 << 30);

    for (int start = 0, f = 0;
        start + frameSize <= downsampled.length && f < maxFrames;
        start += hop * frameStride, f++) {
      final re = Float64List(frameSize);
      final im = Float64List(frameSize);
      for (int i = 0; i < frameSize; i++) {
        final v = downsampled[start + i];
        final hann = 0.5 - 0.5 * math.cos(2 * math.pi * i / (frameSize - 1));
        re[i] = v * hann;
      }
      _fft(re, im);

      final frameChroma = Float64List(_chromaBins);
      double frameEnergy = 0;
      final maxFreq = (effectiveRate / 2) * 0.9;
      for (int bin = 1; bin < frameSize ~/ 2; bin++) {
        final freq = bin * effectiveRate / frameSize;
        if (freq < 60 || freq > maxFreq) continue;
        final mag = math.sqrt(re[bin] * re[bin] + im[bin] * im[bin]);
        if (mag < 1e-6) continue;
        // 24-EDO pitch class: A4 (440Hz) = 69 semitones = 138 quarter tones.
        final midi48 = 138 + 24 * math.log(freq / 440.0) / math.ln2;
        final pc = ((midi48.round() % _chromaBins) + _chromaBins) % _chromaBins;
        frameChroma[pc] += mag;
        // Octave fold: route half of the energy one octave down. Helps when
        // only upper harmonics of the fundamental are captured by the FFT.
        final midi48Down = midi48 - 24;
        if (midi48Down > 0) {
          final pcDown = ((midi48Down.round() % _chromaBins) + _chromaBins) % _chromaBins;
          frameChroma[pcDown] += mag * 0.5;
        }
        frameEnergy += mag;
      }
      if (frameEnergy <= 1e-6) continue;

      for (int i = 0; i < _chromaBins; i++) {
        chroma[i] += frameChroma[i] / frameEnergy;
      }
      frameCount++;
    }

    if (frameCount == 0) return null;

    for (int i = 0; i < _chromaBins; i++) {
      chroma[i] /= frameCount;
    }
    double maxV = 1e-6;
    for (int i = 0; i < _chromaBins; i++) {
      if (chroma[i] > maxV) maxV = chroma[i];
    }
    if (maxV <= 0) return null;

    final result = Float64List(_chromaBins);
    for (int i = 0; i < _chromaBins; i++) {
      result[i] = chroma[i] / maxV;
    }
    return result;
  }

  /// Krumhansl-Schmuckler style correlation between the observed chroma and
  /// the maqam profile (in-scale degrees weight 1, the tonic weight 2).
  /// Mean-centering makes the score robust to non-tonal (noise/drum) energy.
  double _correlation(Float64List chroma, Set<int> template, int tonic) {
    const n = _chromaBins;
    final profile = List<double>.filled(n, 0);
    for (final degree in template) {
      profile[(degree + tonic) % n] = 1.0;
    }
    profile[tonic] = 2.0;

    double meanX = 0, meanP = 0;
    for (int i = 0; i < n; i++) {
      meanX += chroma[i];
      meanP += profile[i];
    }
    meanX /= n;
    meanP /= n;

    double cov = 0, varX = 0, varP = 0;
    for (int i = 0; i < n; i++) {
      final dx = chroma[i] - meanX;
      final dp = profile[i] - meanP;
      cov += dx * dp;
      varX += dx * dx;
      varP += dp * dp;
    }
    if (varX <= 1e-9 || varP <= 1e-9) return 0;
    return cov / math.sqrt(varX * varP);
  }

  // Iterative radix-2 Cooley-Tukey FFT (in-place)
  void _fft(Float64List re, Float64List im) {
    final n = re.length;
    if (n <= 1) return;

    for (int i = 1, j = 0; i < n; i++) {
      int bit = n >> 1;
      for (; j & bit != 0; bit >>= 1) {
        j ^= bit;
      }
      j ^= bit;
      if (i < j) {
        double t = re[i]; re[i] = re[j]; re[j] = t;
        t = im[i]; im[i] = im[j]; im[j] = t;
      }
    }

    for (int len = 2; len <= n; len <<= 1) {
      final ang = -2 * math.pi / len;
      final wRe = math.cos(ang);
      final wIm = math.sin(ang);
      for (int i = 0; i < n; i += len) {
        double cRe = 1, cIm = 0;
        final half = len ~/ 2;
        for (int j = 0; j < half; j++) {
          final uRe = re[i + j];
          final uIm = im[i + j];
          final vRe = re[i + j + half] * cRe - im[i + j + half] * cIm;
          final vIm = re[i + j + half] * cIm + im[i + j + half] * cRe;
          re[i + j] = uRe + vRe;
          im[i + j] = uIm + vIm;
          re[i + j + half] = uRe - vRe;
          im[i + j + half] = uIm - vIm;
          final nRe = cRe * wRe - cIm * wIm;
          cIm = cRe * wIm + cIm * wRe;
          cRe = nRe;
        }
      }
    }
  }
}
