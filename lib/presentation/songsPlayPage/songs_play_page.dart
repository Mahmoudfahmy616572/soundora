import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/core/services/offline_downloads.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/data/sources/lyrics/lyrics_data_source.dart';
import 'package:soundora/presentation/DownloadedSongs/cubit/download_songs_for_offline_cubit.dart';
import 'package:soundora/presentation/DownloadedSongs/cubit/download_songs_for_offline_state.dart';
import 'package:soundora/presentation/LyricsEmotion/cubit/lyrics_emotion_cubit.dart';
import 'package:soundora/presentation/LyricsEmotion/cubit/lyrics_emotion_state.dart';
import 'package:soundora/presentation/LyricsEmotion/models/lyric_emotion_model.dart';
import '../../core/config/assets/app_vectors.dart';
import '../LikedSongs/cubit/favourite_songs_cubit.dart';
import '../LikedSongs/cubit/favourite_songs_state.dart';
import 'cubit/lyrics/lyrics_cubit.dart';
import 'cubit/lyrics/lyrics_state.dart';
import 'cubit/song_player_cubit.dart';
import 'cubit/song_player_state.dart';

import 'cubit/sound_dna/sound_dna_cubit.dart';
import 'cubit/sound_dna/sound_dna_state.dart';
import 'widgets/lyric_share_card.dart';
import '../TimeCapsule/cubit/time_capsule_cubit.dart';
import '../TimeCapsule/widgets/time_capsule_sheet.dart';
import 'widgets/artist_hub_page.dart';

class SongsPlayPage extends StatefulWidget {
  const SongsPlayPage({
    super.key,
    required this.songModel,
    required this.songs,
    required this.index,
  });
  final SongModel songModel;
  final List<SongModel> songs;
  final int index;

  @override
  State<SongsPlayPage> createState() => _SongsPlayPageState();
}

class _SongsPlayPageState extends State<SongsPlayPage>
    with TickerProviderStateMixin {
  static const double _playerArtworkSize = 340.0;
  static const double _lyricsArtworkBadgeSize = 160.0;
  static const Duration _transitionDuration = Duration(milliseconds: 280);
  static const Duration _lyricLineTransitionDuration = Duration(milliseconds: 200);
  static const Curve _transitionCurve = Curves.easeOutCubic;
  static const Curve _lyricLineCurve = Curves.easeOutCubic;

  late final AnimationController _transitionCtrl;
  late final Animation<double> _transitionAnim;
  late final AnimationController _gradientShiftCtrl;
  late final Animation<double> _gradientShiftAnim;
  late final AnimationController _hintCtrl;
  late final Animation<double> _hintAnim;

  bool _isInLyricsMode = false;
  int _currentLyricIndex = -1;
  int _previousLyricIndex = -1;
  Timer? _gradientShiftTimer;
  bool _hintShown = false;

  // â”€â”€ Swipe-to-change track â”€â”€
  // â”€â”€ Swipe-to-change track â”€â”€
  double _swipeOffset = 0.0;
  double _swipeStartOffset = 0.0;
  late final AnimationController _swipeReturnCtrl;
  DateTime? _lastSwipeTime;
  int _lastSwipeDir = 0;
  bool _swipeLocked = false;

  // â”€â”€ Pull-to-dismiss â”€â”€
  double _pullOffset = 0.0;
  double _pullStartOffset = 0.0;
  late final AnimationController _pullReturnCtrl;

  @override
  void initState() {
    super.initState();

    _transitionCtrl = AnimationController(
      vsync: this,
      duration: _transitionDuration,
    );
    _transitionAnim = CurvedAnimation(
      parent: _transitionCtrl,
      curve: _transitionCurve,
    );

    _transitionCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isInLyricsMode) {
        setState(() => _isInLyricsMode = true);
        HapticFeedback.lightImpact();
      } else if (status == AnimationStatus.dismissed && _isInLyricsMode) {
        setState(() => _isInLyricsMode = false);
        HapticFeedback.lightImpact();
      }
    });

    _gradientShiftCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _gradientShiftAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _gradientShiftCtrl, curve: Curves.easeOutCubic),
    );

    _hintCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _hintAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hintCtrl, curve: Curves.easeOutCubic),
    );

    _swipeReturnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _swipeReturnCtrl.addListener(() {
      if (_swipeReturnCtrl.isAnimating && _swipeStartOffset != 0) {
        final t = Curves.easeOutBack.transform(_swipeReturnCtrl.value);
        _swipeOffset = _swipeStartOffset * (1.0 - t);
      }
      setState(() {});
    });
    _swipeReturnCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _swipeOffset = 0.0;
        _swipeStartOffset = 0.0;
      }
    });

    _pullReturnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pullReturnCtrl.addListener(() {
      if (_pullReturnCtrl.isAnimating && _pullStartOffset != 0) {
        final t = Curves.easeOutBack.transform(_pullReturnCtrl.value);
        _pullOffset = _pullStartOffset * (1.0 - t);
      }
      setState(() {});
    });
    _pullReturnCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pullOffset = 0.0;
        _pullStartOffset = 0.0;
      }
    });

    // Check and show one-time breath hint
    _checkAndShowHint();

    final cubit = context.read<SongPlayerCubit>();
    final isDifferent = cubit.playList.isEmpty ||
        cubit.currentIndex >= cubit.playList.length ||
        cubit.playList[cubit.currentIndex].id != widget.songModel.id;
    if (isDifferent) {
      cubit.loadSong(
        widget.songs,
        widget.index,
        widget.songModel.imageUrl,
      );
    }

    context.read<LyricsCubit>().fetchLyrics(
          trackName: widget.songModel.title,
          artistName: widget.songModel.artist,
        );
    context.read<SoundDnaCubit>().fetchSoundDna(
          title: widget.songModel.title,
          artist: widget.songModel.artist,
        );
  }

  @override
  void dispose() {
    _transitionCtrl.dispose();
    _gradientShiftCtrl.dispose();
    _hintCtrl.dispose();
    _swipeReturnCtrl.dispose();
    _pullReturnCtrl.dispose();
    _gradientShiftTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAndShowHint() async {
    final prefs = await SharedPreferences.getInstance();
    _hintShown = prefs.getBool('lyrics_hint_shown') ?? false;
    if (!_hintShown) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        _hintCtrl.forward().then((_) {
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (mounted) _hintCtrl.reverse();
          });
        });
        await prefs.setBool('lyrics_hint_shown', true);
      }
    }
  }

  void _toggleLyricsMode() {
    if (_isInLyricsMode) {
      _transitionCtrl.reverse();
      context.read<SongPlayerCubit>().setLyricsVisible(false);
    } else {
      _transitionCtrl.forward();
      _gradientShiftCtrl.forward();
      context.read<SongPlayerCubit>().setLyricsVisible(true);
    }
  }

  void _handleBadgeDrag(DragUpdateDetails details) {
    if (details.primaryDelta! > 0) {
      _transitionCtrl.value -= details.primaryDelta! / 150;
    }
  }

  void _handleBadgeDragEnd(DragEndDetails details) {
    if (details.primaryVelocity! > 200) {
      _toggleLyricsMode();
    }
  }

  void _onLyricIndexChanged(int newIndex) {
    if (newIndex != _currentLyricIndex && newIndex >= 0) {
      _previousLyricIndex = _currentLyricIndex;
      _currentLyricIndex = newIndex;
      HapticFeedback.selectionClick();
    }
  }

  void _handleSwipeStart(DragStartDetails details) {
    _swipeReturnCtrl.value = 0.0;
  }

  void _handleSwipeUpdate(DragUpdateDetails details) {
    if (_swipeLocked) return;
    double raw = _swipeOffset + details.primaryDelta!;
    final screenW = MediaQuery.of(context).size.width;
    final threshold = screenW * 0.2;
    final clampMax = screenW * 0.4;

    if (raw.abs() < threshold) {
      _swipeOffset = raw;
    } else {
      final beyond = raw.abs() - threshold;
      final resisted = threshold + beyond * 0.35;
      _swipeOffset = raw.sign * resisted.clamp(0, clampMax);
    }
    setState(() {});
  }

  Future<void> _handleSwipeEnd(DragEndDetails details) async {
    if (_swipeLocked) return;
    final screenW = MediaQuery.of(context).size.width;
    final dist = _swipeOffset.abs();
    final vel = details.primaryVelocity ?? 0;
    final absVel = vel.abs();
    final dir = vel > 0 ? -1 : 1;

    final shouldChange = dist > screenW * 0.3 || absVel > 300;

    if (shouldChange) {
      final now = DateTime.now();
      if (_lastSwipeTime != null &&
          dir == _lastSwipeDir &&
          now.difference(_lastSwipeTime!).inMilliseconds < 500) {
        _springBack();
        return;
      }
      _lastSwipeTime = now;
      _lastSwipeDir = dir;
      _swipeLocked = true;
      _swipeOffset = dir * dist.clamp(0, screenW * 0.4);
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      if (vel < 0) {
        context.read<SongPlayerCubit>().playNext();
      } else {
        context.read<SongPlayerCubit>().playPrevious();
      }
      _swipeOffset = 0.0;
      _swipeLocked = false;
    } else {
      _springBack();
    }
  }

  void _springBack() {
    _swipeStartOffset = _swipeOffset;
    _swipeReturnCtrl.forward(from: 0.0);
  }

  void _handlePullUpdate(DragUpdateDetails details) {
    if (_pullReturnCtrl.isAnimating) return;
    final raw = _pullOffset + details.primaryDelta!;
    if (raw < 0) { _pullOffset = raw * 0.3; setState(() {}); return; }
    final threshold = 80.0;
    if (raw < threshold) {
      _pullOffset = raw;
    } else {
      _pullOffset = threshold + (raw - threshold) * 0.4;
    }
    setState(() {});
  }

  Future<void> _handlePullEnd(DragEndDetails details) async {
    if (_pullReturnCtrl.isAnimating) return;
    final vel = details.primaryVelocity ?? 0;
    if (_pullOffset > 200 || vel > 600) {
      HapticFeedback.mediumImpact();
      _pullOffset = _pullOffset.clamp(0, double.infinity);
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 60));
      if (mounted) Navigator.pop(context);
    } else {
      _pullStartOffset = _pullOffset;
      _pullReturnCtrl.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SongPlayerCubit, SongPlayerState>(
      builder: (context, state) {
        final cubit = context.read<SongPlayerCubit>();
        if (state is SongPlayerFailure) {
          return _PlayerErrorView(
            errorMessage: state.errorMessage,
            onRetry: () => cubit.retry(),
            onBack: () => Navigator.pop(context),
          );
        }
        if (cubit.playList.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final currentSong = cubit.playList[cubit.currentIndex];
        final backgroundColor = cubit.dominantColor;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: AnimatedBuilder(
            animation: Listenable.merge([
              _transitionCtrl,
              _gradientShiftAnim,
            ]),
            builder: (context, child) {
              final t = _transitionAnim.value;

return Stack(
                children: [
                  if (_pullOffset > 0)
                    Positioned.fill(
                      child: AnimatedOpacity(
                        opacity: (_pullOffset / 250).clamp(0.0, 0.6),
                        duration: Duration.zero,
                        child: Container(color: Colors.black),
                      ),
                    ),
                  Transform.translate(
                    offset: Offset(0, _pullOffset),
                    child: Stack(
                children: [
                  _AnimatedBackground(
                    t: t,
                    gradientShiftAnim: _gradientShiftAnim,
                    dominantColor: backgroundColor,
                  ),
                  _PlayerContent(
                    t: t,
                    transitionAnim: _transitionAnim,
                    gradientShiftAnim: _gradientShiftAnim,
                    hintAnim: _hintAnim,
                    isInLyricsMode: _isInLyricsMode,
                    currentSong: currentSong,
                    currentLyricIndex: _currentLyricIndex,
                    previousLyricIndex: _previousLyricIndex,
                    onLyricIndexChanged: _onLyricIndexChanged,
                    onToggleLyricsMode: _toggleLyricsMode,
                    onBadgeDragUpdate: _handleBadgeDrag,
                    onBadgeDragEnd: _handleBadgeDragEnd,
                    swipeOffset: _swipeOffset,
                    onSwipeStart: _handleSwipeStart,
                    onSwipeUpdate: _handleSwipeUpdate,
                    onSwipeEnd: _handleSwipeEnd,
                    onPullUpdate: _handlePullUpdate,
                    onPullEnd: _handlePullEnd,
                  ),
                ],
              ),
            ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12.h,
                    left: 20.w,
                    right: 20.w,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -0.12),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: child,
                        ),
                      ),
                      child: (state is SongPlayerLoaded && state.showFullSongPopup)
                          ? _FullSongReadyBanner(
                              key: const ValueKey('fullSongBanner'),
                              resolving: state.fullSongResolving,
                              onPlay: () => context
                                  .read<SongPlayerCubit>()
                                  .resolveFullSong(),
                              onDismiss: () => context
                                  .read<SongPlayerCubit>()
                                  .dismissFullSongPopup(),
                            )
                          : const SizedBox.shrink(key: ValueKey('noBanner')),
                    ),
                  ),
          ],
        );
            },
          ),
        );
      },
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  final double t;
  final Animation<double> gradientShiftAnim;
  final Color dominantColor;

  const _AnimatedBackground({
    required this.t,
    required this.gradientShiftAnim,
    required this.dominantColor,
  });

  @override
  Widget build(BuildContext context) {
    final shift = gradientShiftAnim.value;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xff0f0c29),
            Color.lerp(
                  const Color(0xff302b63),
                  const Color(0xff1a1a3e),
                  shift * 0.5,
                ) ??
                const Color(0xff302b63),
            const Color(0xff24243e),
          ],
          transform: GradientRotation(shift * 0.15),
        ),
      ),
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: (1.0 - t * 0.4).clamp(0.3, 1.0),
          duration: Duration.zero,
          child: Container(
            color: dominantColor.withOpacity(0.25 * (1 - t)),
          ),
        ),
      ),
    );
  }
}

class _PlayerContent extends StatelessWidget {
  final double t;
  final Animation<double> transitionAnim;
  final Animation<double> gradientShiftAnim;
  final Animation<double> hintAnim;
  final bool isInLyricsMode;
  final SongModel currentSong;
  final int currentLyricIndex;
  final int previousLyricIndex;
  final ValueChanged<int> onLyricIndexChanged;
  final VoidCallback onToggleLyricsMode;
  final GestureDragUpdateCallback onBadgeDragUpdate;
  final GestureDragEndCallback onBadgeDragEnd;
  final double swipeOffset;
  final GestureDragStartCallback onSwipeStart;
  final GestureDragUpdateCallback onSwipeUpdate;
  final GestureDragEndCallback onSwipeEnd;
  final GestureDragUpdateCallback onPullUpdate;
  final GestureDragEndCallback onPullEnd;

  const _PlayerContent({
    required this.t,
    required this.transitionAnim,
    required this.gradientShiftAnim,
    required this.hintAnim,
    required this.isInLyricsMode,
    required this.currentSong,
    required this.currentLyricIndex,
    required this.previousLyricIndex,
    required this.onLyricIndexChanged,
    required this.onToggleLyricsMode,
    required this.onBadgeDragUpdate,
    required this.onBadgeDragEnd,
    required this.swipeOffset,
    required this.onSwipeStart,
    required this.onSwipeUpdate,
    required this.onSwipeEnd,
    required this.onPullUpdate,
    required this.onPullEnd,
  });

  @override
  Widget build(BuildContext context) {
    final scale = lerpDouble(
        1.0,
        _SongsPlayPageState._lyricsArtworkBadgeSize /
            _SongsPlayPageState._playerArtworkSize,
        t)!;
    final artworkSize = _SongsPlayPageState._playerArtworkSize * scale;

    final translateY = lerpDouble(0.0, 0.0, t)!;
    final translateX = lerpDouble(0.0, -12.0 * math.sin(t * math.pi), t)!;

    final artworkOpacity = (1.0 - t * 0.15).clamp(0.85, 1.0);
    final songInfoOpacity = (1.0 - t * 1.2).clamp(0.0, 1.0);
    final controlsOpacity = (1.0 - t * 1.0).clamp(0.0, 1.0);
    final compactControlsOpacity = ((t - 0.3) / 0.7).clamp(0.0, 1.0);
    final progressWidth = lerpDouble(1.0, 0.6, t)!;
    final progressHeight = lerpDouble(4.0, 2.0, t)!;

    final Widget badge = GestureDetector(
      onTap: onToggleLyricsMode,
      onHorizontalDragStart: onSwipeStart,
      onHorizontalDragUpdate: onSwipeUpdate,
      onHorizontalDragEnd: onSwipeEnd,
      onVerticalDragUpdate: isInLyricsMode ? onBadgeDragUpdate : onPullUpdate,
      onVerticalDragEnd: isInLyricsMode ? onBadgeDragEnd : onPullEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([]), // No rotation animation
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(translateX + swipeOffset, translateY),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: artworkOpacity,
                    child: RepaintBoundary(
                      child: Hero(
                        tag: 'album_art_${currentSong.id}',
                        child: Container(
                          width: artworkSize.w,
                          height: artworkSize.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                isInLyricsMode ? 16.r : 30.r),
                            color: Colors.grey[300],
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                    isInLyricsMode ? 0.2 : 0.35),
                                blurRadius: isInLyricsMode ? 20 : 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: CachedNetworkImage(
                            imageUrl: currentSong.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.music_note, size: 60),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!isInLyricsMode) _HintOverlay(hintAnim: hintAnim),
              if (swipeOffset != 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: (swipeOffset.abs() / 80).clamp(0.0, 0.6),
                      duration: Duration.zero,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: swipeOffset < 0
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            end: swipeOffset < 0
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            colors: [
                              Colors.white.withOpacity(0),
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0),
                            ],
                            stops: const [0.5, 0.75, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );

    final Widget songInfo = AnimatedOpacity(
      opacity: songInfoOpacity,
      duration: Duration.zero,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentSong.title,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => ArtistHubPage(artistName: currentSong.artist),
                              transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                              transitionDuration: const Duration(milliseconds: 350),
                            ),
                          ),
                          child: Text(
                            currentSong.artist,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.8),
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white.withOpacity(0.3),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      InkWell(
                        onTap: () => _showSoundDNA(context),
                        borderRadius: BorderRadius.circular(12.r),
                        child: Padding(
                          padding: EdgeInsets.all(4.r),
                          child: Icon(
                            Icons.biotech_rounded,
                            size: 18.sp,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      InkWell(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: const Color(0xFF121216),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(28.r),
                            ),
                          ),
                          builder: (_) => BlocProvider(
                            create: (_) => TimeCapsuleCubit(null),
                            child: const TimeCapsuleSheet(),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        child: Padding(
                          padding: EdgeInsets.all(4.r),
                          child: Icon(
                            Icons.hourglass_bottom,
                            size: 18.sp,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _buildMaqamChip(),
                    ],
                  ),
                ],
              ),
            ),
            _buildDownloadFavoriteButtons(),
          ],
        ),
      ),
    );

    final Widget progressBar = isInLyricsMode
        ? _EmotionTimelineScrub(
            t: t,
            progressWidth: progressWidth,
            progressHeight: progressHeight,
          )
        : _MorphingProgressBar(
            t: t,
            progressWidth: progressWidth,
            progressHeight: progressHeight,
          );

    final Widget fullControls = AnimatedOpacity(
      opacity: controlsOpacity,
      duration: Duration.zero,
      child: _FullControls(),
    );

    final Widget compactControls = AnimatedOpacity(
      opacity: compactControlsOpacity,
      duration: Duration.zero,
      child: _CompactControls(),
    );

    final Widget normalMode = SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 24.h),
          badge,
          SizedBox(height: 20.h),
          songInfo,
          SizedBox(height: 40.h),
          progressBar,
          SizedBox(height: 10.h),
          const _FullSongChip(),
          SizedBox(height: 16.h),
          fullControls,
          compactControls,
          SizedBox(height: 8.h),
          SizedBox(height: 40.h),
        ],
      ),
    );

    final Widget lyricsMode = Column(
      children: [
        SizedBox(height: 12.h),
        badge,
        SizedBox(height: 4.h),
        progressBar,
        SizedBox(height: 8.h),
        compactControls,
        Expanded(
          child: _LyricsViewport(
            onLyricIndexChanged: onLyricIndexChanged,
            songTitle: currentSong.title,
            artistName: currentSong.artist,
          ),
        ),
        SizedBox(height: 12.h),
      ],
    );

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: isInLyricsMode ? lyricsMode : normalMode,
          ),
        ],
      ),
    );
  }

    Widget _buildMaqamChip() {
    return BlocBuilder<SongPlayerCubit, SongPlayerState>(
      builder: (context, state) {
        final maqam = context.read<SongPlayerCubit>().currentMaqam;
        if (maqam == null) return const SizedBox.shrink();
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A1E0F), Color(0xFF14100A)],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: const Color(0xFFC9A96A).withOpacity(0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.music_note_rounded,
                size: 12.sp,
                color: const Color(0xFFC9A96A),
              ),
              SizedBox(width: 5.w),
              Text(
                maqam.arabicName,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFC9A96A),
                  fontFamily: 'Satoshi',
                ),
              ),
              SizedBox(width: 5.w),
              Text(
                '${(maqam.confidence * 100).round()}%',
                style: TextStyle(
                  fontSize: 9.sp,
                  color: Colors.white.withOpacity(0.45),
                  fontFamily: 'Satoshi',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDownloadFavoriteButtons() {
    return Row(
      children: [
        BlocBuilder<DownloadSongsForOfflineCubit, DownloadSongsForOfflineState>(
          builder: (context, state) {
            if (state is! DownloadSongsForOfflineLoaded) {
              return IconButton(
                onPressed: () => context
                    .read<DownloadSongsForOfflineCubit>()
                    .downloadSongsForOffline(currentSong),
                icon: const Icon(Icons.downloading_outlined),
                color: Colors.grey,
              );
            }
            final progress = state.downloads[currentSong.id] ?? 0.0;
            final isDownloaded =
                OfflineDownloads.syncPathOf(currentSong.id) != null;
            if (progress > 0 && progress < 1) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2.5,
                    color: Colors.green,
                  ),
                  Text(
                    "${(progress * 100).toInt()}%",
                    style: TextStyle(fontSize: 12.sp, color: Colors.white),
                  ),
                ],
              );
            }
            return IconButton(
              onPressed: () => context
                  .read<DownloadSongsForOfflineCubit>()
                  .downloadSongsForOffline(currentSong),
              icon: isDownloaded
                  ? const Icon(Icons.download_done)
                  : const Icon(Icons.downloading_outlined),
              color: isDownloaded ? Colors.green : Colors.grey,
            );
          },
        ),
        BlocBuilder<FavouriteSongsCubit, FavouriteSongsState>(
          builder: (context, state) {
            bool isFavourite = context
                .watch<FavouriteSongsCubit>()
                .isFavourite(currentSong.id);
            if (state is FavouriteSongsLoaded) {
              isFavourite = state.favouriteSongsIds.contains(
                currentSong.id.toString(),
              );
            }
            return IconButton(
              onPressed: () =>
                  context.read<FavouriteSongsCubit>().toggleFavourite(currentSong),
              icon: Icon(
                isFavourite ? Icons.favorite : Icons.favorite_border,
                color: isFavourite ? Colors.red : Colors.white,
              ),
            );
          },
        ),
      ],
    );
  }

  void _showSoundDNA(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SoundDNABottomSheet(),
    );
  }
}

class _MorphingProgressBar extends StatelessWidget {
  final double t;
  final double progressWidth;
  final double progressHeight;

  const _MorphingProgressBar({
    required this.t,
    required this.progressWidth,
    required this.progressHeight,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SongPlayerCubit, SongPlayerState>(
      builder: (context, state) {
        final cubit = context.read<SongPlayerCubit>();
        return StreamBuilder<Duration>(
          stream: cubit.audioPlayer.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            final total = cubit.songDuration;

            return Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * progressWidth,
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: progressHeight,
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: t > 0.5 ? 0 : 6,
                        ),
                        overlayShape: RoundSliderOverlayShape(
                          overlayRadius: t > 0.5 ? 0 : 12,
                        ),
                        activeTrackColor: AppColors.primaryColor,
                        inactiveTrackColor: Colors.white.withOpacity(0.2),
                        thumbColor: AppColors.primaryColor,
                      ),
                      child: Slider(
                        value: position.inMilliseconds.toDouble().clamp(
                              0.0,
                              total.inMilliseconds.toDouble().clamp(1, double.infinity),
                            ),
                        min: 0.0,
                        max: total.inMilliseconds.toDouble().clamp(1, double.infinity),
                        onChanged: (value) {
                          cubit.seekTo(Duration(milliseconds: value.toInt()));
                        },
                      ),
                    ),
                    if (t < 0.7)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12.sp,
                              ),
                            ),
                            Text(
                              _formatDuration(total),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
          },
        );
  }
}

String _formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _FullControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SongPlayerCubit, SongPlayerState>(
      builder: (context, state) {
        final cubit = context.read<SongPlayerCubit>();
        if (state is! SongPlayerLoaded) return const SizedBox.shrink();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ControlButton(
              icon: AppVectors.repeate,
              isActive: cubit.loopMode != LoopMode.off,
              onTap: () => cubit.toggleRepeatMode(),
            ),
            _ControlButton(
              icon: AppVectors.previousSong,
              onTap: () => cubit.playPrevious(),
            ),
            _PlayPauseButton(),
            _ControlButton(
              icon: AppVectors.nextSong,
              onTap: () => cubit.playNext(),
            ),
            _ControlButton(
              icon: AppVectors.shuffle,
              isActive: cubit.isShuffleMode,
              onTap: () => cubit.toggleShuffleMode(),
            ),
          ],
        );
      },
    );
  }
}

class _CompactControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SongPlayerCubit, SongPlayerState>(
      builder: (context, state) {
        final cubit = context.read<SongPlayerCubit>();
        if (state is! SongPlayerLoaded) return const SizedBox.shrink();

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CompactControlButton(
              icon: AppVectors.previousSong,
              size: 36.w,
              onTap: () => cubit.playPrevious(),
            ),
            SizedBox(width: 32.w),
            _PlayPauseButton(size: 48.w),
            SizedBox(width: 32.w),
            _CompactControlButton(
              icon: AppVectors.nextSong,
              size: 36.w,
              onTap: () => cubit.playNext(),
            ),
          ],
        );
      },
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SvgPicture.asset(
        icon,
        width: 30.w,
        height: 30.h,
        color: isActive ? AppColors.primaryColor : const Color(0xFFA7A7A7),
      ),
    );
  }
}

class _CompactControlButton extends StatelessWidget {
  final String icon;
  final double size;
  final VoidCallback onTap;

  const _CompactControlButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SvgPicture.asset(
        icon,
        width: size,
        height: size,
        color: const Color(0xFFA7A7A7),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final double size;

  const _PlayPauseButton({this.size = 60.0});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SongPlayerCubit, SongPlayerState>(
      builder: (context, state) {
        final cubit = context.read<SongPlayerCubit>();
        if (state is! SongPlayerLoaded) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => cubit.playOrpauseSong(),
          child: Container(
            width: size.w,
            height: size.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor,
            ),
            child: cubit.audioPlayer.playing
                ? const Icon(Icons.pause, color: Colors.white)
                : const Icon(Icons.play_arrow, color: Colors.white),
          ),
        );
      },
    );
  }
}

class _LyricsViewport extends StatefulWidget {
  final ValueChanged<int> onLyricIndexChanged;
  final String songTitle;
  final String artistName;

  const _LyricsViewport({
    required this.onLyricIndexChanged,
    required this.songTitle,
    required this.artistName,
  });

  @override
  State<_LyricsViewport> createState() => _LyricsViewportState();
}

class _LyricsViewportState extends State<_LyricsViewport> {
  DateTime? _manualScrollAt;
  int _frozenPositionIndex = -1;
  int _lastFollowedIndex = -1;

  final List<_EmotionEchoData> _echoes = [];
  int _lastEchoActiveIndex = -1;

  final ItemScrollController _listController = ItemScrollController();

  @override
  void didUpdateWidget(_LyricsViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.songTitle != oldWidget.songTitle ||
        widget.artistName != oldWidget.artistName) {
      _lastEchoActiveIndex = -1;
      _echoes.clear();
      _manualScrollAt = null;
      _frozenPositionIndex = -1;
      _lastFollowedIndex = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LyricsCubit, LyricsState>(
      builder: (context, lyricsState) {
        if (lyricsState is LyricsLoading || lyricsState is LyricsInitial) {
          return SizedBox(
            height: 200.h,
            child: Center(
              child: _ShimmerLyricsLoader(),
            ),
          );
        }

        if (lyricsState is LyricsNotFound) {
          return SizedBox(
            height: 200.h,
            child: Center(
              child: Text(
                'No lyrics available',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 16.sp,
                ),
              ),
            ),
          );
        }

        final parsedLyrics = (lyricsState as LyricsLoaded).lyrics;

        return BlocBuilder<SongPlayerCubit, SongPlayerState>(
          builder: (context, playerState) {
            final isVisible = playerState is SongPlayerLoaded && playerState.isLyricsVisible;
            if (!isVisible) return const SizedBox.shrink();
            return BlocBuilder<LyricsEmotionCubit, LyricsEmotionState>(
              builder: (context, emotionState) {
                return RepaintBoundary(
                  child: StreamBuilder<Duration>(
                    stream: context.read<SongPlayerCubit>().audioPlayer.positionStream,
                    builder: (context, snapshot) {
                      final currentPosition = snapshot.data ?? Duration.zero;

                      // Alignment from full-song analysis (shift + scale) or a
                      // manual nudge; null means raw provider timestamps.
                      final alignment = playerState.alignment;
                      Duration effectiveStart(int k) {
                        final t = parsedLyrics[k].startTime;
                        return alignment != null ? alignment.effectiveTime(t) : t;
                      }

                      final n = parsedLyrics.length;
                      final effTimes =
                          List<Duration>.generate(n, effectiveStart);
                      int activeIndex = -1;
                      for (int k = 0; k < n; k++) {
                        if (currentPosition >= effTimes[k]) {
                          activeIndex = k;
                        } else {
                          break;
                        }
                      }

                      if (activeIndex != -1) {
                        widget.onLyricIndexChanged(activeIndex);
                      }

                      // â”€â”€ Emotion Echo tracking â”€â”€
                      if (activeIndex != _lastEchoActiveIndex) {
                        if (activeIndex >= 0) {
                          final emotionType = emotionState is LyricsEmotionLoaded &&
                                  activeIndex < emotionState.lyricsWithEmotion.length
                              ? emotionState.lyricsWithEmotion[activeIndex].emotion
                              : EmotionType.calm;
                          _echoes.add(_EmotionEchoData(
                            lineIndex: activeIndex,
                            emotion: emotionType,
                            startMs: currentPosition.inMilliseconds.toDouble(),
                          ));
                        }
                        _lastEchoActiveIndex = activeIndex;
                      }
                      _echoes.removeWhere(
                          (e) => (currentPosition.inMilliseconds - e.startMs) > 4000);

                      final bool isFrozen = _manualScrollAt != null &&
                          DateTime.now().difference(_manualScrollAt!).inMilliseconds < 3000;
                      if (!isFrozen) _frozenPositionIndex = -1;
                      final positionIndex = isFrozen && _frozenPositionIndex >= 0
                          ? _frozenPositionIndex
                          : activeIndex;

                      // â”€â”€ Auto-follow: keep the active line centered unless the
                      // user is manually scrolling (3s freeze after a scroll). â”€â”€
                      if (!isFrozen &&
                          positionIndex != _lastFollowedIndex &&
                          positionIndex >= 0) {
                        _lastFollowedIndex = positionIndex;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted || !_listController.isAttached) return;
                          _listController.scrollTo(
                            index: positionIndex,
                            alignment: 0.5,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                          );
                        });
                      }

                      final emotionLines = emotionState is LyricsEmotionLoaded
                          ? emotionState.lyricsWithEmotion
                          : null;

                      double gravityOffset(int idx) {
                        final rel = idx - positionIndex;
                        if (rel == 0) return 0.0;
                        final sign = rel.sign;
                        final abs = rel.abs().toDouble();
                        return sign * 72.0 * (abs / (abs + 0.4));
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final viewportHeight = constraints.maxHeight;

                          return Stack(
                            children: [
                              // 1. Emotion Echo background aura
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _EmotionEchoPainter(
                                    echoes: _echoes,
                                    activeIndex: activeIndex,
                                    currentMs: currentPosition.inMilliseconds.toDouble(),
                                    viewportHeight: viewportHeight,
                                  ),
                                ),
                              ),
                              // 2. Lyrics list (manually scrollable + auto-follow)
                              Positioned.fill(
                                child: NotificationListener<ScrollNotification>(
                                  onNotification: (notification) {
                                    if (notification is UserScrollNotification &&
                                        notification.direction.name != 'idle') {
                                      _manualScrollAt = DateTime.now();
                                      _frozenPositionIndex = activeIndex;
                                    }
                                    return false;
                                  },
                                  child: ScrollablePositionedList.builder(
                                    itemScrollController: _listController,
                                    initialScrollIndex:
                                        positionIndex >= 0 ? positionIndex : 0,
                                    initialAlignment: 0.5,
                                    itemCount: n,
                                    padding: EdgeInsets.symmetric(vertical: 40.h),
                                    itemBuilder: (context, idx) {
                                      final line = parsedLyrics[idx];
                                      final isCurrent = idx == activeIndex;

                                      Color lineColor = isCurrent
                                          ? Colors.white
                                          : Colors.white.withOpacity(
                                              idx == activeIndex - 1 ||
                                                      idx == activeIndex + 1
                                                  ? 0.45
                                                  : 0.25);

                                      if (emotionLines != null &&
                                          idx < emotionLines.length) {
                                        final emotionLine = emotionLines[idx];
                                        final emotion = emotionLine.emotion;
                                        if (!isCurrent) {
                                          lineColor = _emotionColor(
                                              emotion, lineColor.opacity);
                                        }
                                      }

                                      final baseOffset =
                                          gravityOffset(idx) / 48.h;

                                      EmotionType lineEmotion = EmotionType.calm;
                                      double lineIntensity = 0.5;
                                      if (emotionLines != null &&
                                          idx < emotionLines.length) {
                                        lineEmotion = emotionLines[idx].emotion;
                                        lineIntensity =
                                            emotionLines[idx].intensity;
                                      }

                                      final seekTarget = effTimes[idx];
                                      return GestureDetector(
                                        onTap: () => context
                                            .read<SongPlayerCubit>()
                                            .seekTo(seekTarget),
                                        onLongPress: () => _showLyricShareSheet(
                                          lyricText: line.text,
                                          accentColor:
                                              _emotionColor(lineEmotion, 1.0),
                                        ),
                                        child: _AnimatedLyricLine(
                                          key: ValueKey(idx),
                                          text: line.text,
                                          isCurrent: isCurrent,
                                          baseOffset: baseOffset,
                                          color: lineColor,
                                          fontSize: 28.sp,
                                          emotion: lineEmotion,
                                          intensity: lineIntensity,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // 3. Whisper preview of the upcoming line
                              if (activeIndex >= 0 &&
                                  activeIndex + 3 < parsedLyrics.length)
                                Positioned(
                                  bottom: 28.h,
                                  left: 24.w,
                                  right: 24.w,
                                  child: IgnorePointer(
                                    child: _buildWhisperPreview(
                                      parsedLyrics[activeIndex + 3],
                                    ),
                                  ),
                                ),
                              // 4. Breath Canvas overlay
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: _BreathCanvas(
                                  currentMs: currentPosition.inMilliseconds.toDouble(),
                                  parsedLyrics: parsedLyrics,
                                  activeIndex: activeIndex,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      }
    );
  }

  Widget _buildWhisperPreview(LyricLine line) {
    return Opacity(
      opacity: 0.08,
      child: Padding(
        padding: EdgeInsets.only(top: 4.h),
        child: Text(
          line.text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20.sp,
            color: Colors.white,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  final GlobalKey _shareBoundaryKey = GlobalKey();

  void _showLyricShareSheet({
    required String lyricText,
    required Color accentColor,
  }) {
    final renderCard = RepaintBoundary(
      key: _shareBoundaryKey,
      child: LyricShareCard(
        lyricText: lyricText,
        songTitle: widget.songTitle,
        artistName: widget.artistName,
        accentColor: accentColor,
      ),
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF121216),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: EdgeInsets.only(bottom: 16.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  renderCard,
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close),
                          label: const Text('Ø¥Ù„ØºØ§Ø¡'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await LyricShareService.shareCard(
                              boundaryKey: _shareBoundaryKey,
                              songTitle: widget.songTitle,
                              artistName: widget.artistName,
                            );
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Ù…Ø´Ø§Ø±ÙƒØ© Ø§Ù„Ø¨Ø·Ø§Ù‚Ø©'),
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _emotionColor(EmotionType emotion, double baseOpacity) {
    switch (emotion) {
      case EmotionType.love:
        return const Color(0xFFFF6FB5).withOpacity(baseOpacity);
      case EmotionType.sadness:
        return const Color(0xFF4D96FF).withOpacity(baseOpacity);
      case EmotionType.joy:
        return const Color(0xFFFFE066).withOpacity(baseOpacity);
      case EmotionType.anger:
        return const Color(0xFFFF6B6B).withOpacity(baseOpacity);
      case EmotionType.hope:
        return const Color(0xFF4D96FF).withOpacity(baseOpacity);
      case EmotionType.calm:
        return const Color(0xFF92A8D1).withOpacity(baseOpacity);
      case EmotionType.energy:
        return const Color(0xFFFF9F1C).withOpacity(baseOpacity);
      case EmotionType.pain:
        return const Color(0xFFFF6B6B).withOpacity(baseOpacity);
    }
  }
}

class _AnimatedLyricLine extends StatefulWidget {
  final String text;
  final bool isCurrent;
  final double baseOffset;
  final Color color;
  final double fontSize;
  final EmotionType emotion;
  final double intensity;

  const _AnimatedLyricLine({
    super.key,
    required this.text,
    required this.isCurrent,
    required this.baseOffset,
    required this.color,
    required this.fontSize,
    this.emotion = EmotionType.calm,
    this.intensity = 0.5,
  });

  @override
  State<_AnimatedLyricLine> createState() => _AnimatedLyricLineState();
}

class _AnimatedLyricLineState extends State<_AnimatedLyricLine>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offsetAnim;
  late final Animation<double> _opacityAnim;
  late final Animation<double> _scaleAnim;
  late final AnimationController _breathCtrl;
  late final Animation<double> _breathAnim;

  Color get _emotionGlow {
    switch (widget.emotion) {
      case EmotionType.love:
        return const Color(0xFFFF6FB5);
      case EmotionType.sadness:
        return const Color(0xFF4D96FF);
      case EmotionType.joy:
        return const Color(0xFFFFE066);
      case EmotionType.anger:
        return const Color(0xFFFF6B6B);
      case EmotionType.hope:
        return const Color(0xFF4D96FF);
      case EmotionType.calm:
        return const Color(0xFF92A8D1);
      case EmotionType.energy:
        return const Color(0xFFFF9F1C);
      case EmotionType.pain:
        return const Color(0xFFFF6B6B);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _SongsPlayPageState._lyricLineTransitionDuration,
    );
    _offsetAnim = Tween<double>(begin: widget.baseOffset + (widget.isCurrent ? 1 : 0), end: widget.baseOffset).animate(
      CurvedAnimation(parent: _controller, curve: _SongsPlayPageState._lyricLineCurve),
    );
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: _SongsPlayPageState._lyricLineCurve),
    );
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: _SongsPlayPageState._lyricLineCurve),
    );
    _controller.forward();

    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _breathAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );
    if (widget.isCurrent) {
      _breathCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedLyricLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent != oldWidget.isCurrent ||
        widget.baseOffset != oldWidget.baseOffset) {
      _controller.forward(from: 0);
    }
    if (widget.isCurrent && !_breathCtrl.isAnimating) {
      _breathCtrl.repeat(reverse: true);
    } else if (!widget.isCurrent && _breathCtrl.isAnimating) {
      _breathCtrl.stop();
      _breathCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowOpacity = (widget.isCurrent ? 0.22 : 0.05) * (0.4 + widget.intensity * 0.6);
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _breathCtrl]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _offsetAnim.value * 48.h),
          child: Opacity(
            opacity: widget.isCurrent ? 1.0 : _opacityAnim.value * widget.color.opacity,
            child: Transform.scale(
              scale: _scaleAnim.value * (widget.isCurrent ? _breathAnim.value : 1.0),
              child: child,
            ),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Emotion glow behind the line
          Container(
            width: 260.w,
            height: 60.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _emotionGlow.withOpacity(glowOpacity),
                  _emotionGlow.withOpacity(0),
                ],
              ),
            ),
          ),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: widget.isCurrent ? FontWeight.bold : FontWeight.normal,
              color: widget.color,
              height: 1.5,
              shadows: widget.isCurrent
                  ? [
                      Shadow(
                        color: _emotionGlow.withOpacity(0.5 * (0.4 + widget.intensity * 0.6)),
                        blurRadius: 18,
                      ),
                    ]
                  : null,
            ),
            child: Text(widget.text, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}



class _SoundDNABottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SoundDnaCubit, SoundDnaState>(
      builder: (context, state) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: const Color(0xff1a1a2e),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              Container(
                width: 48.w,
                height: 4.h,
                margin: EdgeInsets.only(top: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: _buildContent(state),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(SoundDnaState state) {
    if (state is SoundDnaLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is SoundDnaLoaded) {
      final features = state.songFeatures;
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sound DNA',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              features.title,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 24.h),
            _buildTrait('Energy', features.energy ?? 0),
            _buildTrait('Danceability', features.danceability ?? 0),
            _buildTrait('Acousticness', features.acousticness ?? 0),
            _buildTrait('BPM', features.bpm != null ? features.bpm! / 200 : 0, displayText: features.bpm?.toStringAsFixed(0)),
          ],
        ),
      );
    } else if (state is SoundDnaNotFound) {
      return Center(
        child: Text(
          'No Sound DNA data available',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16.sp),
        ),
      );
    } else if (state is SoundDnaError) {
      return Center(
        child: Text(
          'Error loading Sound DNA',
          style: TextStyle(color: Colors.red, fontSize: 16.sp),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTrait(String label, double value, {String? displayText}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.white, fontSize: 15.sp),
              ),
              Text(
                displayText ?? '${(value * 100).toInt()}%',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 6.h,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerLyricsLoader extends StatelessWidget {
  const _ShimmerLyricsLoader();

  static const List<double> _lineWidths = [250.0, 190.0, 220.0, 160.0];

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850] ?? Colors.grey[800]!,
      highlightColor: Colors.grey[750] ?? Colors.grey[700]!,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (i) {
          return Container(
            margin: EdgeInsets.symmetric(vertical: 7.h),
            width: _lineWidths[i].w,
            height: 12.h,
            decoration: BoxDecoration(
              color: Colors.grey[850] ?? Colors.grey[800],
              borderRadius: BorderRadius.circular(10.r),
            ),
          );
        }),
      ),
    );
  }
}

class _HintOverlay extends StatelessWidget {
  final Animation<double> hintAnim;

  const _HintOverlay({required this.hintAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: hintAnim,
      builder: (context, child) {
        return Opacity(
          opacity: hintAnim.value,
          child: Container(
            width: 140.w,
            height: 32.h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 16.sp,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Ø§Ø¶ØºØ· Ù„Ù„Ø£ØºÙ†ÙŠØ©',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Emotion Echo â€” colored mist/aura behind recently-sung lines
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EmotionEchoData {
  final int lineIndex;
  final EmotionType emotion;
  final double startMs;
  _EmotionEchoData({
    required this.lineIndex,
    required this.emotion,
    required this.startMs,
  });
}

Color _echoEmotionColor(EmotionType emotion) {
  switch (emotion) {
    case EmotionType.love:   return const Color(0xFFFF6FB5);
    case EmotionType.sadness: return const Color(0xFF4D96FF);
    case EmotionType.joy:    return const Color(0xFFFFE066);
    case EmotionType.anger:  return const Color(0xFFFF6B6B);
    case EmotionType.hope:   return const Color(0xFF4D96FF);
    case EmotionType.calm:   return const Color(0xFF92A8D1);
    case EmotionType.energy: return const Color(0xFFFF9F1C);
    case EmotionType.pain:   return const Color(0xFFFF6B6B);
  }
}

class _EmotionEchoPainter extends CustomPainter {
  final List<_EmotionEchoData> echoes;
  final int activeIndex;
  final double currentMs;
  final double viewportHeight;

  _EmotionEchoPainter({
    required this.echoes,
    required this.activeIndex,
    required this.currentMs,
    required this.viewportHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final echo in echoes) {
      final age = (currentMs - echo.startMs) / 1000.0;
      final fade = (1.0 - age / 4.0).clamp(0.0, 1.0);
      if (fade <= 0.01) continue;

      final baseColor = _echoEmotionColor(echo.emotion);
      final dy = (echo.lineIndex - activeIndex) * 72.0 + viewportHeight / 2;

      final paint1 = Paint()
        ..color = baseColor.withOpacity(fade * 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32);
      canvas.drawCircle(Offset(size.width / 2, dy), 80 * fade, paint1);

      final paint2 = Paint()
        ..color = baseColor.withOpacity(fade * 0.04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 56);
      canvas.drawCircle(Offset(size.width / 2, dy), 140 * fade, paint2);
    }
  }

  @override
  bool shouldRepaint(_EmotionEchoPainter old) =>
      old.currentMs != currentMs || old.activeIndex != activeIndex;
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Breath Canvas â€” subtle breathing pulse between lyric pauses
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _BreathCanvas extends StatefulWidget {
  final double currentMs;
  final List<LyricLine> parsedLyrics;
  final int activeIndex;

  const _BreathCanvas({
    required this.currentMs,
    required this.parsedLyrics,
    required this.activeIndex,
  });

  @override
  State<_BreathCanvas> createState() => _BreathCanvasState();
}

class _BreathCanvasState extends State<_BreathCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _breath;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _breath = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeIdx = widget.activeIndex;
    final lyrics = widget.parsedLyrics;

    bool nearPause = false;
    if (activeIdx >= 0 && activeIdx + 1 < lyrics.length) {
      final gap = lyrics[activeIdx + 1].startTime - lyrics[activeIdx].startTime;
      if (gap > const Duration(seconds: 3)) {
        nearPause = true;
      }
    }
    if (!nearPause && activeIdx >= 0 && lyrics.isNotEmpty) {
      final lineEnd = lyrics[activeIdx >= lyrics.length ? lyrics.length - 1 : activeIdx].startTime;
      final elapsed = widget.currentMs - lineEnd.inMilliseconds.toDouble();
      if (elapsed > 3000 && elapsed < 8000) nearPause = true;
    }

    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        return Opacity(
          opacity: nearPause ? _breath.value * 0.4 : _breath.value * 0.12,
          child: child,
        );
      },
      child: Center(
        child: Container(
          width: 120.w,
          height: 120.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.0,
            ),
          ),
          child: Center(
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Emotion Timeline Scrub â€” colored segments for each lyric line
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EmotionTimelineScrub extends StatefulWidget {
  final double t;
  final double progressWidth;
  final double progressHeight;

  const _EmotionTimelineScrub({
    required this.t,
    required this.progressWidth,
    required this.progressHeight,
  });

  @override
  State<_EmotionTimelineScrub> createState() => _EmotionTimelineScrubState();
}

class _EmotionTimelineScrubState extends State<_EmotionTimelineScrub> {
  double? _hoverMs;
  int? _hoverLineIndex;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SongPlayerCubit>();
    final totalMs = cubit.songDuration.inMilliseconds.toDouble();

    return BlocBuilder<LyricsEmotionCubit, LyricsEmotionState>(
      builder: (context, emotionState) {
        final emotions = emotionState is LyricsEmotionLoaded
            ? emotionState.lyricsWithEmotion
            : null;

        return BlocBuilder<SongPlayerCubit, SongPlayerState>(
          builder: (context, playerState) {
            final lyricsCubit = context.read<LyricsCubit>();
            final lyricsState = lyricsCubit.state;
            final parsedLyrics = lyricsState is LyricsLoaded ? lyricsState.lyrics : <LyricLine>[];

            return StreamBuilder<Duration>(
              stream: cubit.audioPlayer.positionStream,
              builder: (context, snapshot) {
                final positionMs = snapshot.data?.inMilliseconds.toDouble() ?? 0.0;
                final alignment = playerState is SongPlayerLoaded
                    ? playerState.alignment
                    : null;
                final syncOffset = alignment?.shiftMs ?? 0;

                return Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * widget.progressWidth,
                    height: widget.progressHeight + 8.h,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (d) {
                        final box = context.findRenderObject() as RenderBox;
                        final localPos = box.globalToLocal(d.globalPosition);
                        final fraction = (localPos.dx / box.size.width).clamp(0.0, 1.0);
                        final seekMs = fraction * totalMs;
                        setState(() {
                          _hoverMs = seekMs;
                          _hoverLineIndex = _findLineAtMs(parsedLyrics, seekMs);
                        });
                        cubit.seekTo(Duration(milliseconds: seekMs.toInt()));
                      },
                      onTapUp: (d) {
                        final box = context.findRenderObject() as RenderBox;
                        final localPos = box.globalToLocal(d.localPosition);
                        final fraction = (localPos.dx / box.size.width).clamp(0.0, 1.0);
                        final seekMs = fraction * totalMs;
                        cubit.seekTo(Duration(milliseconds: seekMs.toInt()));
                      },
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _TimelinePainter(
                          lyrics: parsedLyrics,
                          emotions: emotions,
                          positionMs: positionMs,
                          totalMs: totalMs,
                           syncOffsetMs: syncOffset.toDouble(),
                          hoverMs: _hoverMs,
                          hoverLineIndex: _hoverLineIndex,
                          height: widget.progressHeight,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  int _findLineAtMs(List<LyricLine> lyrics, double ms) {
    for (int i = lyrics.length - 1; i >= 0; i--) {
      if (ms >= lyrics[i].startTime.inMilliseconds.toDouble()) return i;
    }
    return -1;
  }
}

class _TimelinePainter extends CustomPainter {
  final List<LyricLine> lyrics;
  final List<LyricEmotion>? emotions;
  final double positionMs;
  final double totalMs;
  final double syncOffsetMs;
  final double? hoverMs;
  final int? hoverLineIndex;
  final double height;

  _TimelinePainter({
    required this.lyrics,
    required this.emotions,
    required this.positionMs,
    required this.totalMs,
    required this.syncOffsetMs,
    required this.hoverMs,
    required this.hoverLineIndex,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    final r = height / 2;
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, (size.height - height) / 2, size.width, height),
      Radius.circular(r),
    );
    canvas.drawRRect(trackRect, trackPaint);

    if (lyrics.isEmpty) return;

    final baseMs = lyrics.first.startTime.inMilliseconds.toDouble();
    final effectiveEnd = totalMs > 0 ? totalMs : (lyrics.last.startTime.inMilliseconds + 5000).toDouble();
    final range = effectiveEnd - baseMs;
    if (range <= 0) return;

    for (int i = 0; i < lyrics.length; i++) {
      final line = lyrics[i];
      final lineMs = line.startTime.inMilliseconds.toDouble();
      final nextMs = i + 1 < lyrics.length
          ? lyrics[i + 1].startTime.inMilliseconds.toDouble()
          : effectiveEnd;
      final x1 = ((lineMs - baseMs) / range * size.width).clamp(0.0, size.width);
      final x2 = ((nextMs - baseMs) / range * size.width).clamp(0.0, size.width);

      final emotion = emotions != null && i < emotions!.length
          ? emotions![i].emotion
          : EmotionType.calm;
      final color = _echoEmotionColor(emotion).withOpacity(0.5);

      final segRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(x1, (size.height - height) / 2, x2, (size.height + height) / 2),
        Radius.circular(r),
      );
      canvas.drawRRect(segRect, Paint()..color = color);
    }

    final posFrac = ((positionMs - baseMs) / range).clamp(0.0, 1.0);
    final posX = posFrac * size.width;
    final thumbPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(posX, size.height / 2), height / 2 + 2, thumbPaint);
    canvas.drawCircle(
      Offset(posX, size.height / 2),
      height / 2 + 2,
      Paint()
        ..color = AppColors.primaryColor.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    if (hoverMs != null) {
      final hFrac = ((hoverMs! - baseMs) / range).clamp(0.0, 1.0);
      final hx = hFrac * size.width;
      final dotPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(Offset(hx, size.height / 2), height / 2 + 5, dotPaint);

      if (hoverLineIndex != null && hoverLineIndex! >= 0 && hoverLineIndex! < lyrics.length) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: lyrics[hoverLineIndex!].text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.rtl,
          maxLines: 1,
          ellipsis: '...',
        )..layout(maxWidth: size.width * 0.3);

        final previewY = (size.height - height) / 2 - textPainter.height - 4;
        if (previewY > 0) {
          final previewBg = Paint()
            ..color = const Color(0xFF1A1A2E).withOpacity(0.85)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawRect(
            Rect.fromLTWH(
              hx - textPainter.width / 2 - 6,
              previewY - 2,
              textPainter.width + 12,
              textPainter.height + 4,
            ),
            previewBg,
          );
          textPainter.paint(canvas, Offset(hx - textPainter.width / 2, previewY));
        }
      }
    }
  }

  @override
  bool shouldRepaint(_TimelinePainter old) =>
      old.positionMs != positionMs || old.hoverMs != hoverMs;
}

class _PlayerErrorView extends StatefulWidget {
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _PlayerErrorView({
    required this.errorMessage,
    required this.onRetry,
    required this.onBack,
  });

  @override
  State<_PlayerErrorView> createState() => _PlayerErrorViewState();
}

class _PlayerErrorViewState extends State<_PlayerErrorView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E13),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1D1430), Color(0xFF0E0E13)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildGlowIcon(),
                  SizedBox(height: 30.h),
                  Text(
                    'ØªØ¹Ø°Ø± ØªØ´ØºÙŠÙ„ Ø§Ù„Ø£ØºÙ†ÙŠØ©',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Satoshi',
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'ÙŠÙ…ÙƒÙ† ÙŠÙƒÙˆÙ† ÙÙŠÙ‡ Ù…Ø´ÙƒÙ„Ø© ÙÙŠ Ø§Ù„Ø§ØªØµØ§Ù„ Ø¨Ø§Ù„Ø¥Ù†ØªØ±Ù†ØªØŒ Ø£Ùˆ Ø¥Ù† Ù…ØµØ¯Ø± Ø§Ù„Ø£ØºÙ†ÙŠØ© Ù…Ø´ Ù…ØªØ§Ø­ Ø¯Ù„ÙˆÙ‚ØªÙŠ. Ø¬Ø±Ù‘Ø¨ Ø¥Ø¹Ø§Ø¯Ø© Ø§Ù„Ù…Ø­Ø§ÙˆÙ„Ø© Ø£Ùˆ Ø§Ø®ØªØ§Ø± Ø£ØºÙ†ÙŠØ© ØªØ§Ù†ÙŠØ©.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 13.5.sp,
                      height: 1.5,
                      fontFamily: 'Satoshi',
                    ),
                  ),
                  if (widget.errorMessage != null) ...[
                    SizedBox(height: 18.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14.sp,
                            color: Colors.white.withOpacity(0.4),
                          ),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: Text(
                              widget.errorMessage!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 11.sp,
                                fontFamily: 'Satoshi',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 36.h),
                  _buildPrimaryButton(),
                  SizedBox(height: 10.h),
                  _buildGhostButton(),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlowIcon() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        return Container(
          width: 96.w,
          height: 96.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7B2FBE), Color(0xFF5B21B6)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor
                    .withOpacity(0.35 * (0.6 + 0.4 * t)),
                blurRadius: 30 * (1 + t * 0.5),
                spreadRadius: 2 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: const Icon(
        Icons.music_off_rounded,
        size: 44,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onRetry,
        borderRadius: BorderRadius.circular(18.r),
        child: Ink(
          width: double.infinity,
          height: 54.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7B2FBE), Color(0xFFA855F7)],
            ),
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.4),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh_rounded, size: 20.sp, color: Colors.white),
              SizedBox(width: 10.w),
              Text(
                'Ø¥Ø¹Ø§Ø¯Ø© Ø§Ù„Ù…Ø­Ø§ÙˆÙ„Ø©',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Satoshi',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGhostButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onBack,
        borderRadius: BorderRadius.circular(18.r),
        child: Ink(
          width: double.infinity,
          height: 50.h,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16.sp,
                color: Colors.white.withOpacity(0.75),
              ),
              SizedBox(width: 8.w),
              Text(
                'Ø±Ø¬ÙˆØ¹',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Satoshi',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullSongReadyBanner extends StatelessWidget {
  final VoidCallback onPlay;
  final VoidCallback onDismiss;
  final bool resolving;

  const _FullSongReadyBanner({
    super.key,
    required this.onPlay,
    required this.onDismiss,
    this.resolving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xE61A1A1E),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 20.sp,
              color: AppColors.primaryColor,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Ø¨Ø±ÙŠÙÙŠÙˆ 30 Ø«Ø§Ù†ÙŠØ© â€” Ø§Ø¶ØºØ· Ù„Ù„ØªØ´ØºÙŠÙ„ Ø§Ù„ÙƒØ§Ù…Ù„',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Satoshi',
                ),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: resolving ? null : onPlay,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: resolving
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        'ØªØ´ØºÙŠÙ„',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Satoshi',
                        ),
                      ),
              ),
            ),
            SizedBox(width: 4.w),
            GestureDetector(
              onTap: onDismiss,
              child: Padding(
                padding: EdgeInsets.all(6.r),
                child: Icon(
                  Icons.close_rounded,
                  size: 18.sp,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-song affordance shown only after the "full song" banner disappears, so
/// the user still has a way to ask for the full track without the two
/// competing for attention at the same time.
class _FullSongChip extends StatelessWidget {
  const _FullSongChip();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SongPlayerCubit, SongPlayerState>(
      builder: (context, state) {
        if (state is! SongPlayerLoaded ||
            state.isFullSong ||
            state.showFullSongPopup) {
          return const SizedBox.shrink();
        }
        final resolving = state.fullSongResolving;
        return GestureDetector(
          onTap: resolving ? null : () => context.read<SongPlayerCubit>().resolveFullSong(),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (resolving)
                  SizedBox(
                    width: 14.w,
                    height: 14.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryColor,
                    ),
                  )
                else
                  Icon(
                    Icons.play_circle_fill_rounded,
                    size: 16.sp,
                    color: AppColors.primaryColor,
                  ),
                SizedBox(width: 6.w),
                Text(
                  resolving ? 'Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªØ­Ù…ÙŠÙ„...' : 'Ø´ØºÙ‘Ù„ Ø§Ù„Ø£ØºÙ†ÙŠØ© Ø§Ù„ÙƒØ§Ù…Ù„Ø©',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Satoshi',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}