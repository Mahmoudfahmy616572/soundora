import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/presentation/KaraokeMode/cubit/karaoke_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/lyrics/lyrics_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/lyrics/lyrics_state.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_state.dart';

class KaraokePage extends StatefulWidget {
  const KaraokePage({super.key});

  @override
  State<KaraokePage> createState() => _KaraokePageState();
}

class _KaraokePageState extends State<KaraokePage>
    with SingleTickerProviderStateMixin {
  final ItemScrollController _itemScrollController = ItemScrollController();
  int _currentLineIndex = -1;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late KaraokeCubit _karaokeCubit;

  @override
  void initState() {
    super.initState();
    _karaokeCubit = KaraokeCubit();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _karaokeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _karaokeCubit,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: BlocBuilder<LyricsCubit, LyricsState>(
          builder: (context, lyricsState) {
            return BlocBuilder<SongPlayerCubit, SongPlayerState>(
              builder: (context, playerState) {
                if (lyricsState is! LyricsLoaded ||
                    lyricsState.lyrics.isEmpty) {
                  return _buildEmptyState();
                }
                _karaokeCubit.setLyrics(lyricsState.lyrics);
                return _buildKaraokeView(lyricsState, playerState);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lyrics, color: Colors.grey[700], size: 80.sp),
          SizedBox(height: 20.h),
          Text(
            'No Lyrics Available',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Lyrics will appear here when available',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 30.h),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            iconSize: 30.sp,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildKaraokeView(
      LyricsLoaded lyricsState, SongPlayerState playerState) {
    final alignment = playerState is SongPlayerLoaded
        ? playerState.alignment
        : null;
    _karaokeCubit.setAlignment(alignment);

    Duration effectiveTime(Duration raw) =>
        alignment?.effectiveTime(raw) ?? raw;
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                AppColors.primaryColor.withOpacity(0.08),
                const Color(0xFF0A0A0A),
              ],
            ),
          ),
        ),
        Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.white),
                      iconSize: 32.sp,
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'KARAOKE',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                        letterSpacing: 4,
                      ),
                    ),
                    SizedBox(width: 48.w),
                  ],
                ),
              ),
            ),
            _buildScoreHeader(),
            Expanded(
              child: StreamBuilder<Duration>(
                stream: context
                    .read<SongPlayerCubit>()
                    .audioPlayer
                    .positionStream,
                builder: (context, snapshot) {
                  final currentPosition = snapshot.data ?? Duration.zero;
                  final parsedLyrics = lyricsState.lyrics;

                  int activeIndex = parsedLyrics.lastIndexWhere(
                      (line) => currentPosition >= effectiveTime(line.startTime));

                  if (activeIndex != -1 &&
                      activeIndex != _currentLineIndex &&
                      _itemScrollController.isAttached) {
                    _currentLineIndex = activeIndex;
                    _karaokeCubit.updateCurrentLine(activeIndex);
                    _itemScrollController.scrollTo(
                      index: activeIndex,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOutCubic,
                      alignment: 0.35,
                    );
                  }

                  return ScrollablePositionedList.builder(
                    itemScrollController: _itemScrollController,
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    itemCount: parsedLyrics.length,
                    itemBuilder: (context, index) {
                      final line = parsedLyrics[index];
                      final isActive = index == activeIndex;
                      final isPast = index < activeIndex;

                      return GestureDetector(
                        onTap: _karaokeCubit.isRecording
                            ? () => _karaokeCubit.onLineTapped(
                                  index,
                                  currentPosition,
                                )
                            : null,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: isActive ? _pulseAnimation.value : 1.0,
                              child: child,
                            );
                          },
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 400),
                            style: TextStyle(
                              fontSize: isActive ? 28.sp : 20.sp,
                              fontWeight: isActive
                                  ? FontWeight.w900
                                  : isPast
                                      ? FontWeight.w400
                                      : FontWeight.w500,
                              color: isActive
                                  ? Colors.white
                                  : isPast
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.5),
                              height: 1.6,
                              shadows: isActive
                                  ? [
                                      Shadow(
                                        color: AppColors.primaryColor
                                            .withOpacity(0.6),
                                        blurRadius: 20,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              line.text,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreHeader() {
    return BlocBuilder<KaraokeCubit, KaraokeState>(
      builder: (context, state) {
        if (state is! KaraokeRecording && state is! KaraokeResult) {
          return SizedBox(height: 4.h);
        }

        final score = state is KaraokeRecording
            ? state.score
            : state is KaraokeResult
                ? state.score
                : 0;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: AppColors.primaryColor, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Score: $score%',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (state is KaraokeResult) ...[
                SizedBox(width: 16.w),
                Text(
                  '${state.linesCompleted}/${state.totalLines} lines',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white54,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomControls() {
    return BlocBuilder<SongPlayerCubit, SongPlayerState>(
      builder: (context, state) {
        final cubit = context.read<SongPlayerCubit>();
        return SafeArea(
          top: false,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: StreamBuilder<Duration>(
              stream: cubit.audioPlayer.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final total = cubit.songDuration;
                return Column(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.primaryColor,
                        inactiveTrackColor: Colors.grey[800],
                        thumbColor: AppColors.primaryColor,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5),
                        trackHeight: 2.h,
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 12),
                      ),
                      child: Slider(
                        value: position.inSeconds
                            .toDouble()
                            .clamp(0.0, total.inSeconds.toDouble()),
                        min: 0.0,
                        max: total.inSeconds.toDouble() > 0
                            ? total.inSeconds.toDouble()
                            : 1.0,
                        onChanged: (value) {
                          cubit.seekTo(Duration(seconds: value.toInt()));
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style:
                              TextStyle(color: Colors.grey, fontSize: 12.sp),
                        ),
                        Text(
                          _formatDuration(total),
                          style:
                              TextStyle(color: Colors.grey, fontSize: 12.sp),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.skip_previous,
                              color: Colors.white, size: 32.sp),
                          onPressed: () => cubit.playPrevious(),
                        ),
                        SizedBox(width: 12.w),
                        BlocBuilder<KaraokeCubit, KaraokeState>(
                          builder: (context, karaokeState) {
                            final isActive = _karaokeCubit.isRecording;
                            return GestureDetector(
                              onTap: () {
                                if (isActive) {
                                  _karaokeCubit.stopSession();
                                } else {
                                  _karaokeCubit.startSession();
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: isActive ? 72.w : 64.w,
                                height: isActive ? 72.w : 64.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive
                                      ? Colors.red
                                      : AppColors.primaryColor,
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color:
                                                Colors.red.withOpacity(0.4),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  isActive ? Icons.stop : Icons.mic,
                                  color: Colors.white,
                                  size: isActive ? 32.sp : 30.sp,
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(width: 12.w),
                        IconButton(
                          icon: Icon(Icons.skip_next,
                              color: Colors.white, size: 32.sp),
                          onPressed: () => cubit.playNext(),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }
}
