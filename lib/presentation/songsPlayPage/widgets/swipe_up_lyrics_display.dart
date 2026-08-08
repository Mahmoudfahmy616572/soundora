import 'dart:async';

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/core/services/lyric_alignment.dart';
import 'package:soundora/data/sources/lyrics/lyrics_data_source.dart';
import 'package:soundora/presentation/LyricsEmotion/cubit/lyrics_emotion_cubit.dart';
import 'package:soundora/presentation/LyricsEmotion/cubit/lyrics_emotion_state.dart';
import 'package:soundora/presentation/LyricsEmotion/models/lyric_emotion_model.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/lyrics/lyrics_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/lyrics/lyrics_state.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_state.dart';

class SwipeUpLyricsDisplay extends StatefulWidget {
  const SwipeUpLyricsDisplay({super.key});

  @override
  State<SwipeUpLyricsDisplay> createState() => _SwipeUpLyricsDisplayState();
}

class _SwipeUpLyricsDisplayState extends State<SwipeUpLyricsDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _hintAnimation;
  int _hintBounceCount = 0;
  bool _hintTriggered = false;
  String? _lastHintSongId;
  bool _lyricsAvailable = false;
  StreamSubscription<Duration>? _positionSubscription;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _hintAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _hintAnimation.dispose();
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _startPositionListening() {
    _positionSubscription?.cancel();
    _positionSubscription = context
        .read<SongPlayerCubit>()
        .audioPlayer
        .positionStream
        .listen((position) {
      if (mounted) setState(() => _currentPosition = position);
    });
  }

  void _stopPositionListening() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  List<String> _extractLines(List<LyricLine> lyricLines) {
    return lyricLines.map((l) => l.text).where((t) => t.isNotEmpty).toList();
  }

  int _getCurrentLineIndex(
      List<LyricLine> lyricLines, Duration position, LyricAlignment? alignment) {
    if (lyricLines.isEmpty) return -1;
    int index = -1;
    for (int i = 0; i < lyricLines.length; i++) {
      final t = lyricLines[i].startTime;
      final effective = alignment != null ? alignment.effectiveTime(t) : t;
      if (position >= effective) {
        index = i;
      } else {
        break;
      }
    }
    return index;
  }

  void _handleLyricsState(LyricsState lyricsState, SongPlayerState playerState) {
    final hasLyrics = lyricsState is LyricsLoaded && lyricsState.lyrics.isNotEmpty;

    if (hasLyrics) {
      final songId = (playerState is SongPlayerLoaded && playerState.playlist.isNotEmpty)
          ? playerState.playlist[playerState.currentIndex].id.toString()
          : null;

      if (songId != null && songId != _lastHintSongId) {
        _lastHintSongId = songId;
        _hintTriggered = false;
        _hintBounceCount = 0;
        _lyricsAvailable = false;
      }

      if (!_lyricsAvailable && !_hintTriggered) {
        _lyricsAvailable = true;
      }

      if (!(_positionSubscription?.isPaused ?? false) &&
          playerState is SongPlayerLoaded && playerState.isLyricsVisible) {
        _startPositionListening();
      } else {
        _stopPositionListening();
      }
    } else {
      _lyricsAvailable = false;
      _stopPositionListening();
    }
  }

  void _startHintAnimation() {
    if (!mounted) return;
    if (_hintBounceCount >= 1) return;
    _hintAnimation.forward(from: 0.0).whenComplete(() {
      if (!mounted) return;
      _hintAnimation.reverse(from: 1.0).whenComplete(() {
        if (!mounted) return;
        _hintBounceCount++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LyricsCubit, LyricsState>(
      builder: (context, lyricsState) {
        return BlocBuilder<SongPlayerCubit, SongPlayerState>(
          builder: (context, playerState) {
            _handleLyricsState(lyricsState, playerState);

            final hasLyrics = lyricsState is LyricsLoaded && lyricsState.lyrics.isNotEmpty;
            final isVisible = playerState is SongPlayerLoaded && playerState.isLyricsVisible;

            if (isVisible && hasLyrics) {
              return _buildLyricsView(lyricsState.lyrics, playerState);
            }

            if (_lyricsAvailable && !_hintTriggered && hasLyrics) {
              _hintTriggered = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _startHintAnimation();
              });
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildLyricsView(List<LyricLine> lyricLines, SongPlayerState playerState) {
    final lines = _extractLines(lyricLines);
    final alignment = playerState is SongPlayerLoaded ? playerState.alignment : null;
    final currentIndex = _getCurrentLineIndex(lyricLines, _currentPosition, alignment);

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
          context.read<SongPlayerCubit>().toggleShowLyrics();
        }
      },
      child: Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        top: 0,
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
              child: BlocBuilder<LyricsEmotionCubit, LyricsEmotionState>(
                builder: (context, emotionState) {
                  List<LyricEmotion> emotionLines = [];
                  if (emotionState is LyricsEmotionLoaded) {
                    emotionLines = emotionState.lyricsWithEmotion;
                  }

                  return Column(
                    children: [
                      SizedBox(height: 30.h),
                      Expanded(
                        child: Center(
                          child: ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: lines.length,
                            padding: EdgeInsets.symmetric(horizontal: 40.w),
                            itemBuilder: (context, index) {
                              final isCurrent = index == currentIndex;
                              final distance = (index - currentIndex).abs();
                              final opacity = distance == 0
                                  ? 1.0
                                  : (1.0 - (distance * 0.12)).clamp(0.25, 1.0);
                              final scale = isCurrent
                                  ? 1.08
                                  : (1.0 - (distance * 0.02)).clamp(0.88, 1.0);

                              Color lineColor = AppColors.grey.withOpacity(0.5);
                              double lineFontSize = 18.sp;
                              FontWeight lineFontWeight = FontWeight.w500;
                              double lineHeight = 1.3;
                              double letterSpacing = 0.2;
                              if (isCurrent) {
                                lineFontSize = 24.sp;
                                lineFontWeight = FontWeight.bold;
                                lineHeight = 1.4;
                                letterSpacing = 0.5;
                              }

                              if (emotionLines.isNotEmpty && index < emotionLines.length) {
                                final emotion = emotionLines[index];
                                lineColor = isCurrent
                                    ? emotion.color
                                    : emotion.color.withOpacity(0.4);
                              }

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                margin: EdgeInsets.symmetric(vertical: 6.h),
                                child: Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 4.h),
                                    decoration: isCurrent
                                        ? BoxDecoration(
                                            borderRadius: BorderRadius.circular(8.r),
                                            color: lineColor.withOpacity(0.08),
                                          )
                                        : null,
                                    alignment: Alignment.center,
                                    child: Text(
                                      lines[index],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: lineFontSize,
                                        fontWeight: lineFontWeight,
                                        color: lineColor.withOpacity(opacity),
                                        height: lineHeight,
                                        letterSpacing: letterSpacing,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 30.h),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}