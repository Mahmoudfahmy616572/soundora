import 'package:equatable/equatable.dart';
import 'package:flutter/painting.dart';
import 'package:soundora/core/services/lyric_alignment.dart';
import 'package:soundora/data/models/songs/songs_model.dart';

abstract class SongPlayerState extends Equatable {
  final int currentIndex;
  final List<SongModel> playlist;
  final bool isPlaying;
  final Duration songPosition;
  final Duration songDuration;
  final Color dominantColor;

  const SongPlayerState({
    this.currentIndex = 0,
    this.isPlaying = false,
    this.playlist = const [],
    this.songPosition = Duration.zero,
    this.songDuration = Duration.zero,
    this.dominantColor = const Color(0xff121212),
  });

  SongModel? get currentSong =>
      playlist.isNotEmpty && currentIndex < playlist.length
          ? playlist[currentIndex]
          : null;

  @override
  List<Object?> get props =>
      [currentIndex, playlist.length, isPlaying, songPosition, songDuration, dominantColor];
}

class SongPlayerLoading extends SongPlayerState {
  const SongPlayerLoading();
}

class SongPlayerLoaded extends SongPlayerState {
  final bool isLyricsVisible;
  final bool showFullSongPopup;
  final bool fullSongResolving;
  final bool isFullSong;
  final LyricAlignment? alignment;

  const SongPlayerLoaded({
    required this.isLyricsVisible,
    this.showFullSongPopup = false,
    this.fullSongResolving = false,
    this.isFullSong = false,
    this.alignment,
    super.currentIndex,
    super.playlist,
    super.isPlaying,
    super.songPosition,
    super.songDuration,
    super.dominantColor,
  });

  SongPlayerLoaded copyWith({
    bool? isLyricsVisible,
    bool? showFullSongPopup,
    bool? fullSongResolving,
    bool? isFullSong,
    LyricAlignment? alignment,
    int? currentIndex,
    List<SongModel>? playlist,
    bool? isPlaying,
    Duration? songPosition,
    Duration? songDuration,
    Color? dominantColor,
  }) {
    return SongPlayerLoaded(
      isLyricsVisible: isLyricsVisible ?? this.isLyricsVisible,
      showFullSongPopup: showFullSongPopup ?? this.showFullSongPopup,
      fullSongResolving: fullSongResolving ?? this.fullSongResolving,
      isFullSong: isFullSong ?? this.isFullSong,
      alignment: alignment ?? this.alignment,
      currentIndex: currentIndex ?? this.currentIndex,
      playlist: playlist ?? this.playlist,
      isPlaying: isPlaying ?? this.isPlaying,
      songPosition: songPosition ?? this.songPosition,
      songDuration: songDuration ?? this.songDuration,
      dominantColor: dominantColor ?? this.dominantColor,
    );
  }

  @override
  List<Object?> get props => [
        isLyricsVisible,
        showFullSongPopup,
        fullSongResolving,
        isFullSong,
        alignment,
        currentIndex,
        playlist.length,
        isPlaying,
        songPosition,
        songDuration,
        dominantColor,
      ];
}

final class SongPlayerFailure extends SongPlayerState {
  final String? errorMessage;

  const SongPlayerFailure({this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
