import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/core/services/maqam_detector.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/presentation/Maqam/cubit/maqam_cubit.dart';
import 'package:soundora/presentation/Maqam/cubit/maqam_state.dart';
import 'package:soundora/presentation/Maqam/maqam_catalog.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/songs_play_page.dart';
import 'package:soundora/serviece_locator.dart';

class MaqamDiscoveryPage extends StatefulWidget {
  const MaqamDiscoveryPage({super.key});

  @override
  State<MaqamDiscoveryPage> createState() => _MaqamDiscoveryPageState();
}

class _MaqamDiscoveryPageState extends State<MaqamDiscoveryPage> {
  MaqamResult? _liveMaqam;
  StreamSubscription<dynamic>? _playerSub;

  @override
  void initState() {
    super.initState();
    context.read<MaqamCubit>().loadMaqams();
    _liveMaqam = getIt<SongPlayerCubit>().currentMaqam;
    _playerSub = getIt<SongPlayerCubit>().stream.listen((_) {
      final next = getIt<SongPlayerCubit>().currentMaqam;
      if (next != _liveMaqam && mounted) {
        setState(() => _liveMaqam = next);
      }
    });
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    super.dispose();
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
          'اكتشف مقامك',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        children: [
          _buildLiveMaqamCard(),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              'المقامات الثمانية',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          BlocBuilder<MaqamCubit, MaqamState>(
            builder: (context, state) {
              if (state is MaqamLoading) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 48.h),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  ),
                );
              }
              if (state is MaqamFailure) {
                return _buildError(state.message);
              }
              final maqams = MaqamInfo.all;
              return Column(
                children: [
                  for (final maqam in maqams)
                    _MaqamTile(maqam: maqam),
                ],
              );
            },
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildLiveMaqamCard() {
    final info = MaqamInfo.fromResult(_liveMaqam);
    return GestureDetector(
      onTap: () {
        final key = info?.key ?? 'Rast';
        final songs = context.read<MaqamCubit>().songsFor(key) ?? const [];
        _openMaqamSongs(info ?? MaqamInfo.all.first, songs);
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              (info?.color ?? AppColors.primaryColor).withOpacity(0.35),
              AppColors.primaryColor.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: (info?.color ?? AppColors.primaryColor).withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                color: (info?.color ?? AppColors.primaryColor),
                shape: BoxShape.circle,
              ),
              child: Icon(
                info?.icon ?? Icons.graphic_eq,
                color: const Color(0xFF121212),
                size: 28.sp,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المقام الحالي',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _liveMaqam == null
                        ? 'شغّل أغنية لاكتشاف مقامها'
                        : '${info?.arabicName ?? _liveMaqam!.englishName} — ${info?.englishName ?? ''}',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_liveMaqam != null)
                    Text(
                      'نسبة الثقة ${(_liveMaqam!.confidence * 100).round()}% · النغمة الأساس ${_liveMaqam!.tonicName}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32.h),
      child: Column(
        children: [
          Text(
            message,
            style: TextStyle(color: Colors.white54, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () => context.read<MaqamCubit>().loadMaqams(),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  void _openMaqamSongs(MaqamInfo maqam, List<SongModel> songs) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaqamSongsPage(maqam: maqam, songs: songs),
      ),
    );
  }
}

class _MaqamTile extends StatelessWidget {
  final MaqamInfo maqam;
  const _MaqamTile({required this.maqam});

  @override
  Widget build(BuildContext context) {
    final count = context.select<MaqamCubit, int>(
      (cubit) => cubit.songCount(maqam.key),
    );
    return GestureDetector(
      onTap: () {
        final songs = context.read<MaqamCubit>().songsFor(maqam.key) ?? const [];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MaqamSongsPage(maqam: maqam, songs: songs),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: maqam.color.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: maqam.color.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(maqam.icon, color: maqam.color, size: 22.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    maqam.arabicName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${maqam.englishName} · ${maqam.jins}',
                    style: TextStyle(fontSize: 11.sp, color: Colors.white54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (count > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: maqam.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(fontSize: 12.sp, color: maqam.color),
                ),
              ),
            SizedBox(width: 8.w),
            Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 14.sp),
          ],
        ),
      ),
    );
  }
}

class MaqamSongsPage extends StatelessWidget {
  final MaqamInfo maqam;
  final List<SongModel> songs;
  const MaqamSongsPage({super.key, required this.maqam, required this.songs});

  void _playRadio(BuildContext context) {
    if (songs.isEmpty) return;
    final playerCubit = context.read<SongPlayerCubit>();
    playerCubit.loadSong(songs, 0, songs.first.imageUrl);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongsPlayPage(
          songModel: songs.first,
          songs: songs,
          index: 0,
        ),
      ),
    );
  }

  void _playSong(BuildContext context, int index) {
    final playerCubit = context.read<SongPlayerCubit>();
    playerCubit.loadSong(songs, index, songs[index].imageUrl);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongsPlayPage(
          songModel: songs[index],
          songs: songs,
          index: index,
        ),
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
          'مقام ${maqam.arabicName}',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: songs.isEmpty
          ? Center(
              child: Text(
                'لا توجد أغانٍ في هذا المقام بعد',
                style: TextStyle(color: Colors.white54, fontSize: 14.sp),
              ),
            )
          : ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        maqam.color.withOpacity(0.35),
                        AppColors.primaryColor.withOpacity(0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    children: [
                      Icon(maqam.icon, color: maqam.color, size: 34.sp),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              maqam.arabicName,
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              maqam.description,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  height: 46.h,
                  child: ElevatedButton.icon(
                    onPressed: () => _playRadio(context),
                    icon: const Icon(Icons.radio),
                    label: Text('شغّل راديو الماكام (${songs.length})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                for (int i = 0; i < songs.length; i++)
                  _buildSongTile(context, i),
              ],
            ),
    );
  }

  Widget _buildSongTile(BuildContext context, int index) {
    final song = songs[index];
    return GestureDetector(
      onTap: () => _playSong(context, index),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: CachedNetworkImage(
                imageUrl: song.imageUrl,
                width: 46.w,
                height: 46.w,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 46.w,
                  height: 46.w,
                  color: Colors.grey[800],
                  child: Icon(Icons.music_note,
                      color: Colors.white54, size: 20.sp),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    song.artist,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.play_circle_outline,
                color: Colors.white38, size: 22.sp),
          ],
        ),
      ),
    );
  }
}
