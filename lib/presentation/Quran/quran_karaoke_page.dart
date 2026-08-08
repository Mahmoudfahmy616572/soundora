import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/core/services/quran_catalog.dart';
import 'package:soundora/presentation/Quran/cubit/quran_cubit.dart';
import 'package:soundora/presentation/Quran/cubit/quran_state.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_state.dart';

/// Recitation karaoke: ayah-by-ayah highlighting synced to the surah audio.
///
/// Ayah timings are estimated proportionally to the ayah text lengths over the
/// total surah duration (deterministic, no DSP needed), then refined as the
/// true duration is reported by the player.
class QuranKaraokePage extends StatefulWidget {
  final QuranSurah surah;
  const QuranKaraokePage({super.key, required this.surah});

  @override
  State<QuranKaraokePage> createState() => _QuranKaraokePageState();
}

class _QuranKaraokePageState extends State<QuranKaraokePage>
    with SingleTickerProviderStateMixin {
  final ItemScrollController _scrollController = ItemScrollController();
  StreamSubscription<dynamic>? _playerSub;

  List<String>? _ayahs;
  List<double> _boundaries = const [];
  int _currentIndex = 0;
  int _durationMs = 0;
  int _positionMs = 0;
  bool _isPlaying = false;
  bool _loadFailed = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.02)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _start();
  }

  Future<void> _start() async {
    final quranCubit = context.read<QuranCubit>();
    final ayahs = await quranCubit.ayahsFor(widget.surah.number);
    if (!mounted) return;
    if (ayahs.isEmpty) {
      setState(() => _loadFailed = true);
      return;
    }
    _ayahs = ayahs;
    _boundaries = _computeBoundaries(ayahs);

    final model = quranCubit.songFor(widget.surah);
    final player = context.read<SongPlayerCubit>();
    _playerSub = player.stream.listen(_onPlayerEvent);
    await player.loadSong([model], 0, '');
  }

  List<double> _computeBoundaries(List<String> ayahs) {
    final total = ayahs.fold<int>(0, (sum, a) => sum + a.length);
    if (total <= 0) return List.filled(ayahs.length, 0);
    final boundaries = <double>[];
    var acc = 0.0;
    for (final ayah in ayahs) {
      acc += ayah.length / total;
      boundaries.add(acc);
    }
    boundaries[boundaries.length - 1] = 1.0;
    return boundaries;
  }

  void _onPlayerEvent(dynamic event) {
    final state = event;
    if (state is! SongPlayerLoaded) return;
    final durationMs = state.songDuration.inMilliseconds;
    final positionMs = state.songPosition.inMilliseconds;

    final nextIndex = _ayahIndexFor(positionMs, durationMs);
    final nextPlaying = state.isPlaying;
    final indexChanged = nextIndex != _currentIndex;
    final playingChanged = nextPlaying != _isPlaying;
    final movedEnough = (positionMs - _positionMs).abs() >= 1000;

    if (indexChanged || playingChanged || movedEnough) {
      setState(() {
        _currentIndex = nextIndex;
        _durationMs = durationMs;
        _positionMs = positionMs;
        _isPlaying = nextPlaying;
      });
      if (indexChanged) _scrollToAyah(nextIndex);
    }
  }

  int _ayahIndexFor(int positionMs, int durationMs) {
    final ayahs = _ayahs;
    if (ayahs == null || ayahs.isEmpty) return 0;
    if (durationMs <= 0) return 0;
    final fraction = positionMs / durationMs;
    var index = 0;
    for (int i = 0; i < _boundaries.length; i++) {
      if (fraction >= _boundaries[i]) index = i;
    }
    return index;
  }

  void _scrollToAyah(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.32,
      );
    });
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatMs(int ms) {
    final s = ms ~/ 1000;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final reciter =
        context.read<QuranCubit>().state is QuranLoaded
            ? (context.read<QuranCubit>().state as QuranLoaded).reciter
            : 'المنشاوي';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'سورة ${widget.surah.arabicName}',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${widget.surah.ayahCount} آية · $reciter',
                          style: TextStyle(fontSize: 12.sp, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.replay, color: Colors.white54, size: 22),
                    onPressed: () {
                      context.read<SongPlayerCubit>().seekTo(Duration.zero);
                      setState(() => _positionMs = 0);
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
            _buildPlayerControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadFailed) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, color: Colors.grey[700], size: 60.sp),
            SizedBox(height: 12.h),
            Text(
              'النص غير متاح',
              style: TextStyle(fontSize: 18.sp, color: Colors.white),
            ),
            SizedBox(height: 4.h),
            Text(
              'لا يمكن تحميل نص السورة الآن',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    if (_ayahs == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: [
            AppColors.primaryColor.withOpacity(0.16),
            const Color(0xFF0A0A0A),
          ],
        ),
      ),
      child: ScrollablePositionedList.builder(
        itemScrollController: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        itemCount: _ayahs!.length,
        itemBuilder: (context, index) => _AyahView(
          index: index,
          text: _ayahs![index],
          highlighted: index == _currentIndex,
          pulse: _pulseAnimation,
          pulseActive: index == _currentIndex && _isPlaying,
        ),
      ),
    );
  }

  Widget _buildPlayerControls() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primaryColor,
              inactiveTrackColor: Colors.white12,
              thumbColor: AppColors.primaryColor,
              trackHeight: 4.h,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              min: 0,
              max: _durationMs <= 0 ? 1 : _durationMs.toDouble(),
              value: (_durationMs <= 0 ? 0 : _positionMs.clamp(0, _durationMs))
                  .toDouble(),
              onChanged: (v) {
                context.read<SongPlayerCubit>().seekTo(
                      Duration(milliseconds: v.round()),
                    );
                setState(() => _positionMs = v.round());
              },
            ),
          ),
          Row(
            children: [
              Text(
                _formatMs(_positionMs),
                style: TextStyle(fontSize: 12.sp, color: Colors.white54),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause_circle : Icons.play_circle,
                  color: Colors.white,
                  size: 46.sp,
                ),
                onPressed: () =>
                    context.read<SongPlayerCubit>().playOrpauseSong(),
              ),
              const Spacer(),
              Text(
                _formatMs(_durationMs),
                style: TextStyle(fontSize: 12.sp, color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AyahView extends StatelessWidget {
  final int index;
  final String text;
  final bool highlighted;
  final Animation<double> pulse;
  final bool pulseActive;

  const _AyahView({
    required this.index,
    required this.text,
    required this.highlighted,
    required this.pulse,
    required this.pulseActive,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    Widget content = Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primaryColor.withOpacity(0.18)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: highlighted
              ? AppColors.primaryColor.withOpacity(0.6)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              style: TextStyle(
                fontSize: 23.sp,
                height: 1.7,
                fontWeight: highlighted ? FontWeight.bold : FontWeight.w400,
                color: highlighted ? Colors.white : Colors.white70,
                fontFamilyFallback: const ['Cairo'],
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Container(
            margin: EdgeInsets.only(top: 4.h),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: highlighted
                  ? AppColors.primaryColor
                  : Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Text(
              _arabicNumber(index + 1),
              style: TextStyle(
                fontSize: 11.sp,
                color: highlighted ? const Color(0xFF121212) : Colors.white54,
                fontFamilyFallback: const ['Cairo'],
              ),
            ),
          ),
        ],
      ),
    );

    if (pulseActive) {
      return ScaleTransition(scale: pulse, child: content);
    }
    return content;
  }
}

String _arabicNumber(int n) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n.toString().split('').map((c) => digits[int.parse(c)]).join();
}
