import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/presentation/LyricsEmotion/cubit/lyrics_emotion_cubit.dart';
import 'package:soundora/presentation/LyricsEmotion/cubit/lyrics_emotion_state.dart';
import 'package:soundora/presentation/LyricsEmotion/models/lyric_emotion_model.dart';
import 'package:soundora/presentation/LyricsEmotion/widgets/emotion_background.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_state.dart';

class EmotionLyricsDisplay extends StatefulWidget {
  const EmotionLyricsDisplay({super.key});

  @override
  State<EmotionLyricsDisplay> createState() => _EmotionLyricsDisplayState();
}

class _EmotionLyricsDisplayState extends State<EmotionLyricsDisplay> {
  final ItemScrollController _scrollController = ItemScrollController();
  int _lastScrolledIndex = -1;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SongPlayerCubit, SongPlayerState>(
      listener: (context, playerState) {
        final position = context.read<SongPlayerCubit>().songPosition;
        context.read<LyricsEmotionCubit>().updateCurrentLine(position);
      },
      child: BlocBuilder<LyricsEmotionCubit, LyricsEmotionState>(
        builder: (context, emotionState) {
          if (emotionState is! LyricsEmotionLoaded) {
            return const SizedBox.shrink();
          }

          if (emotionState.currentLineIndex != _lastScrolledIndex &&
              _scrollController.isAttached) {
            _lastScrolledIndex = emotionState.currentLineIndex;
            _scrollController.scrollTo(
              index: emotionState.currentLineIndex,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              alignment: 0.5,
            );
          }

          return Stack(
            children: [
              EmotionBackground(
                dominantEmotion: emotionState.dominantEmotion,
              ),
              _buildLyricsList(emotionState),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLyricsList(LyricsEmotionLoaded state) {
    return ScrollablePositionedList.builder(
      itemCount: state.lyricsWithEmotion.length,
      itemScrollController: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemBuilder: (context, index) {
        final lyric = state.lyricsWithEmotion[index];
        final isActive = index == state.currentLineIndex;

        return _EmotionLyricLine(
          lyric: lyric,
          isActive: isActive,
        );
      },
    );
  }
}

class _EmotionLyricLine extends StatelessWidget {
  final LyricEmotion lyric;
  final bool isActive;

  const _EmotionLyricLine({
    required this.lyric,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(8.r),
          bottomRight: Radius.circular(8.r),
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: lyric.color.withOpacity(0.3),
                  blurRadius: 20.r,
                  spreadRadius: 2.r,
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildColorBar(),
          SizedBox(width: 12.w),
          Expanded(child: _buildText()),
        ],
      ),
    );
  }

  Widget _buildColorBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: isActive ? 4.w : 3.w,
      height: isActive ? 40.h : 28.h,
      decoration: BoxDecoration(
        color: lyric.color.withOpacity(isActive ? 1.0 : 0.4),
        borderRadius: BorderRadius.circular(2.r),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: lyric.color.withOpacity(0.6),
                  blurRadius: 8.r,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildText() {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 350),
      style: TextStyle(
        fontSize: isActive ? 20.sp : 16.sp,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        color: isActive
            ? lyric.color
            : AppColors.grey.withOpacity(0.6),
        fontFamily: 'Satoshi',
        height: 1.5,
        shadows: isActive
            ? [
                Shadow(
                  color: lyric.color.withOpacity(0.4),
                  blurRadius: 12.r,
                ),
              ]
            : null,
      ),
      child: Text(lyric.text),
    );
  }
}
