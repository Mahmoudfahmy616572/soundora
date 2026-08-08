import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundora/data/sources/lyrics/lyrics_data_source.dart';
import 'package:soundora/presentation/LyricsEmotion/models/lyric_emotion_model.dart';
import 'package:soundora/presentation/LyricsEmotion/cubit/lyrics_emotion_state.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/lyrics/lyrics_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/lyrics/lyrics_state.dart';

class LyricsEmotionCubit extends Cubit<LyricsEmotionState> {
  final LyricsCubit _lyricsCubit;
  late final StreamSubscription<LyricsState> _lyricsSubscription;

  LyricsEmotionCubit({required LyricsCubit lyricsCubit})
      : _lyricsCubit = lyricsCubit,
        super(LyricsEmotionInitial()) {
    _lyricsSubscription = _lyricsCubit.stream.listen(_onLyricsChanged);
  }

  void _onLyricsChanged(LyricsState lyricsState) {
    if (lyricsState is LyricsLoaded) {
      _analyzeEmotions(lyricsState.lyrics);
    } else {
      emit(LyricsEmotionInitial());
    }
  }

  void _analyzeEmotions(List<LyricLine> lyrics) {
    final List<LyricEmotion> emotionLyrics = lyrics.map((line) {
      final result = _analyzeLine(line.text.toLowerCase());
      return LyricEmotion(
        text: line.text,
        startTime: line.startTime,
        emotion: result.$1,
        color: _emotionColor(result.$1),
        intensity: result.$2,
      );
    }).toList();

    final dominant = _computeDominantEmotion(emotionLyrics);
    emit(LyricsEmotionLoaded(
      lyricsWithEmotion: emotionLyrics,
      dominantEmotion: dominant,
    ));
  }

  void updateCurrentLine(Duration position) {
    if (state is! LyricsEmotionLoaded) return;
    final loaded = state as LyricsEmotionLoaded;
    final lyrics = loaded.lyricsWithEmotion;

    int index = 0;
    for (int i = lyrics.length - 1; i >= 0; i--) {
      if (position >= lyrics[i].startTime) {
        index = i;
        break;
      }
    }

    if (index != loaded.currentLineIndex) {
      final windowEnd = (index + 8).clamp(0, lyrics.length);
      final window = lyrics.sublist(0, windowEnd);
      final dominant = _computeDominantEmotion(window);
      emit(loaded.copyWith(
        currentLineIndex: index,
        dominantEmotion: dominant,
      ));
    }
  }

  EmotionType _computeDominantEmotion(List<LyricEmotion> lyrics) {
    final Map<EmotionType, double> scores = {};
    for (final lyric in lyrics) {
      scores[lyric.emotion] = (scores[lyric.emotion] ?? 0) + lyric.intensity;
    }
    if (scores.isEmpty) return EmotionType.calm;
    return scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  (EmotionType, double) _analyzeLine(String text) {
    final Map<EmotionType, double> scores = {
      EmotionType.love: _scoreKeywords(text, _loveKeywords),
      EmotionType.sadness: _scoreKeywords(text, _sadnessKeywords),
      EmotionType.joy: _scoreKeywords(text, _joyKeywords),
      EmotionType.anger: _scoreKeywords(text, _angerKeywords),
      EmotionType.hope: _scoreKeywords(text, _hopeKeywords),
      EmotionType.calm: _scoreKeywords(text, _calmKeywords),
      EmotionType.energy: _scoreKeywords(text, _energyKeywords),
      EmotionType.pain: _scoreKeywords(text, _painKeywords),
    };

    final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final intensity = best.value.clamp(0.0, 1.0);
    return (best.key, intensity == 0 ? 0.3 : intensity);
  }

  double _scoreKeywords(String text, List<String> keywords) {
    double score = 0;
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        score += 0.3;
      }
    }
    return score.clamp(0.0, 1.0);
  }

  Color _emotionColor(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.love:
        return const Color(0xFFE91E63);
      case EmotionType.sadness:
        return const Color(0xFF1565C0);
      case EmotionType.joy:
        return const Color(0xFFFFC107);
      case EmotionType.anger:
        return const Color(0xFFD32F2F);
      case EmotionType.hope:
        return const Color(0xFF26A69A);
      case EmotionType.calm:
        return const Color(0xFF7B2FBE);
      case EmotionType.energy:
        return const Color(0xFFFF6F00);
      case EmotionType.pain:
        return const Color(0xFF6A1B9A);
    }
  }

  static const List<String> _loveKeywords = [
    'heart', 'love', 'kiss', 'baby', 'sweet', 'together',
    'forever', 'darling', 'beloved', 'adore', 'embrace', 'passion',
  ];

  static const List<String> _sadnessKeywords = [
    'cry', 'tears', 'gone', 'broken', 'lost', 'alone', 'empty',
    'goodbye', 'miss', 'lonely', 'mourn', 'weep', 'sorrow',
  ];

  static const List<String> _joyKeywords = [
    'happy', 'smile', 'dance', 'celebrate', 'good', 'bright',
    'laugh', 'fun', 'party', 'shine', 'glory', 'wonderful',
  ];

  static const List<String> _angerKeywords = [
    'hate', 'angry', 'fight', 'burn', 'rage', 'war',
    'destroy', 'fury', 'mad', 'violence', 'revenge', 'rage',
  ];

  static const List<String> _hopeKeywords = [
    'dream', 'believe', 'tomorrow', 'wish', 'rise', 'shine',
    'hope', 'faith', 'pray', 'light', 'free', 'new',
  ];

  static const List<String> _calmKeywords = [
    'peace', 'quiet', 'gentle', 'soft', 'breeze', 'still',
    'calm', 'rest', 'serene', 'tranquil', 'silence', 'slow',
  ];

  static const List<String> _energyKeywords = [
    'run', 'jump', 'fast', 'loud', 'fire', 'power', 'strong',
    'go', 'move', 'rush', 'explode', 'thunder', 'unstoppable',
  ];

  static const List<String> _painKeywords = [
    'hurt', 'scar', 'wound', 'suffer', 'ache', 'deep',
    'bleed', 'pain', 'agony', 'torture', 'destroy', 'shatter',
  ];

  @override
  Future<void> close() {
    _lyricsSubscription.cancel();
    return super.close();
  }
}
