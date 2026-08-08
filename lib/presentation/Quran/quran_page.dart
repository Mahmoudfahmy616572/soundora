import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/config/theme/app_colors.dart';
import '../../../core/services/quran_catalog.dart';
import '../songsPlayPage/cubit/song_player_cubit.dart';
import '../songsPlayPage/songs_play_page.dart';
import '../../serviece_locator.dart';
import 'quran_karaoke_page.dart';
import 'cubit/quran_cubit.dart';
import 'cubit/quran_state.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  static const List<String> _reciters = [
    'المنشاوي',
    'الحصري',
    'عبدالباسط',
    'السديس',
    'الشريم',
    'ماهر المعيقلي',
  ];

  DateTime? _lastSaveAt;
  int _lastSavedPositionMs = -1;

  @override
  void initState() {
    super.initState();
    context.read<QuranCubit>().load();
    getIt<SongPlayerCubit>().stream.listen(_onPlayerEvent);
  }

  void _onPlayerEvent(dynamic event) {
    final cubit = context.read<SongPlayerCubit>();
    final song = cubit.state.currentSong;
    if (song == null || !song.id.toString().startsWith('quran_')) return;
    final number = int.tryParse(song.id.toString().substring(6));
    if (number == null) return;

    final now = DateTime.now();
    final posMs = cubit.songPosition.inMilliseconds;
    if (_lastSaveAt != null &&
        now.difference(_lastSaveAt!) < const Duration(seconds: 5) &&
        (posMs - _lastSavedPositionMs).abs() < 5000) {
      return;
    }
    _lastSaveAt = now;
    _lastSavedPositionMs = posMs;
    context.read<QuranCubit>().markPlayed(number, posMs, cubit.songDuration.inMilliseconds);
  }

  Future<void> _playSurah(QuranSurah surah, {int startAtMs = 0}) async {
    final model = context.read<QuranCubit>().songFor(surah);
    final player = context.read<SongPlayerCubit>();
    await player.loadSong([model], 0, '');
    if (startAtMs > 0) player.seekTo(Duration(milliseconds: startAtMs));
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongsPlayPage(songModel: model, songs: [model], index: 0),
      ),
    );
  }

  void _openKaraoke(QuranSurah surah) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuranKaraokePage(surah: surah),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'المصحف',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: BlocBuilder<QuranCubit, QuranState>(
        builder: (context, state) {
          if (state is! QuranLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            );
          }
          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            children: [
              _buildHeader(state),
              if (state.continueSurah != null) ...[
                SizedBox(height: 16.h),
                _buildContinueCard(state),
              ],
              SizedBox(height: 20.h),
              _buildReciterRow(state),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  'سور القرآن الكريم (${state.surahs.length})',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              for (final surah in state.surahs)
                _buildSurahTile(state, surah),
              SizedBox(height: 24.h),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(QuranLoaded state) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D4F2B), Color(0xFF1B8A4C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            width: 54.w,
            height: 54.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book, color: Colors.white, size: 28),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'القرآن الكريم',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${state.surahs.length} سورة · ٦٢٣٦ آية · ترتيل كامل',
                  style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                ),
                SizedBox(height: 6.h),
                Text(
                  '${_completedCount(state)} سورة ختمتها · ${state.progress.length} في تتبعك',
                  style: TextStyle(fontSize: 12.sp, color: Colors.white.withOpacity(0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _completedCount(QuranLoaded state) =>
      state.progress.values.where((p) => p.completed).length;

  Widget _buildContinueCard(QuranLoaded state) {
    final surah = state.continueSurah!;
    final progress = state.progress[surah.number];
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'واصل التلاوة',
            style: TextStyle(fontSize: 12.sp, color: Colors.white70),
          ),
          SizedBox(height: 4.h),
          Text(
            'سورة ${surah.arabicName}',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (progress != null)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: progress.ratio,
                  minHeight: 5.h,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primaryColor),
                ),
              ),
            ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _playSurah(surah, startAtMs: progress?.positionMs ?? 0),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text(
                    'استكمال التلاوة',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              OutlinedButton.icon(
                onPressed: () => _openKaraoke(surah),
                icon: const Icon(Icons.graphic_eq, size: 18),
                label: Text('كراريوكي', style: TextStyle(fontSize: 12.sp)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
                  side: BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReciterRow(QuranLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'القارئ',
            style: TextStyle(fontSize: 14.sp, color: Colors.white70),
          ),
        ),
        SizedBox(height: 8.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final reciter in _reciters)
                Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: ChoiceChip(
                    label: Text(reciter),
                    selected: state.reciter == reciter,
                    onSelected: (_) =>
                        context.read<QuranCubit>().setReciter(reciter),
                    selectedColor: AppColors.primaryColor,
                    backgroundColor: Colors.white.withOpacity(0.06),
                    labelStyle: TextStyle(
                      color: state.reciter == reciter
                          ? Colors.white
                          : Colors.white70,
                      fontSize: 13.sp,
                    ),
                    side: BorderSide.none,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSurahTile(QuranLoaded state, QuranSurah surah) {
    final progress = state.progress[surah.number];
    return GestureDetector(
      onTap: () => _playSurah(surah),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12.r),
          border: progress != null && progress.completed
              ? Border.all(color: const Color(0xFF2E7D32).withOpacity(0.5))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: progress?.completed == true
                    ? const Color(0xFF2E7D32).withOpacity(0.25)
                    : AppColors.primaryColor.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: progress?.completed == true
                  ? const Icon(Icons.check, color: Color(0xFF4CAF50), size: 18)
                  : Text(
                      '${surah.number}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سورة ${surah.arabicName}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${QuranCatalog.revelationLabel(surah.number)} · ${surah.ayahCount} آية · صفحة ${surah.pageStart}',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (progress != null && progress.ratio > 0 && !progress.completed)
                    Padding(
                      padding: EdgeInsets.only(top: 5.h),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3.r),
                        child: LinearProgressIndicator(
                          value: progress.ratio,
                          minHeight: 3.h,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primaryColor),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.graphic_eq, color: Colors.white38, size: 20),
              onPressed: () => _openKaraoke(surah),
            ),
            const Icon(Icons.play_circle_outline, color: Colors.white38, size: 22),
          ],
        ),
      ),
    );
  }
}
