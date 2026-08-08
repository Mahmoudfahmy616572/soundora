import 'package:equatable/equatable.dart';
import 'package:soundora/presentation/LyricsEmotion/models/lyric_emotion_model.dart';

abstract class LyricsEmotionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LyricsEmotionInitial extends LyricsEmotionState {}

class LyricsEmotionLoading extends LyricsEmotionState {}

class LyricsEmotionLoaded extends LyricsEmotionState {
  final List<LyricEmotion> lyricsWithEmotion;
  final int currentLineIndex;
  final EmotionType dominantEmotion;

  LyricsEmotionLoaded({
    required this.lyricsWithEmotion,
    this.currentLineIndex = 0,
    this.dominantEmotion = EmotionType.calm,
  });

  LyricsEmotionLoaded copyWith({
    List<LyricEmotion>? lyricsWithEmotion,
    int? currentLineIndex,
    EmotionType? dominantEmotion,
  }) {
    return LyricsEmotionLoaded(
      lyricsWithEmotion: lyricsWithEmotion ?? this.lyricsWithEmotion,
      currentLineIndex: currentLineIndex ?? this.currentLineIndex,
      dominantEmotion: dominantEmotion ?? this.dominantEmotion,
    );
  }

  @override
  List<Object?> get props => [lyricsWithEmotion, currentLineIndex, dominantEmotion];
}
