import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/common/appbar/basic_appbar.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/core/widgets/shimmer_widgets.dart';
import 'package:soundora/presentation/LyricsMemory/cubit/lyrics_memory_cubit.dart';
import 'package:soundora/presentation/LyricsMemory/cubit/lyrics_memory_state.dart';
import 'package:soundora/presentation/LyricsMemory/models/lyrics_memory_model.dart';

class LyricsMemoryPage extends StatelessWidget {
  const LyricsMemoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LyricsMemoryCubit()..loadMemory(),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: BasicAppbar(
          isLeading: true,
          title: Text(
            'Lyrics Memory',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: BlocBuilder<LyricsMemoryCubit, LyricsMemoryState>(
          builder: (context, state) {
            if (state is LyricsMemoryLoading) {
              return const SongListShimmer();
            }
            if (state is! LyricsMemoryLoaded) {
              return const SizedBox.shrink();
            }
            if (state.allEntries.isEmpty) {
              return _buildEmptyState();
            }
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsHeader(state.stats),
                  if (state.forgottenSongs.isNotEmpty) ...[
                    _sectionTitle('Forgotten Songs', Icons.history, Colors.white54),
                    _buildForgottenList(state.forgottenSongs),
                  ],
                  if (state.recentSongs.isNotEmpty) ...[
                    _sectionTitle('This Week\'s Journey', Icons.timeline, AppColors.primaryColor),
                    _buildJourneyTimeline(state.recentSongs),
                  ],
                  if (state.onThisDaySongs.isNotEmpty) ...[
                    _sectionTitle('On This Day', Icons.wb_sunny, const Color(0xFFFFBE0B)),
                    _buildOnThisDayList(state.onThisDaySongs),
                  ],
                  SizedBox(height: 40.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note, color: Colors.white24, size: 80.sp),
          SizedBox(height: 16.h),
          Text(
            'Your lyrics memory is empty',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Text(
              'Start listening to songs and your lyrics memory will be built automatically',
              style: TextStyle(fontSize: 14.sp, color: Colors.white38),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(LyricsMemoryStats stats) {
    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withOpacity(0.3),
            const Color(0xFF121212),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('${stats.totalUniqueSongs}', 'Songs'),
          _statItem('${stats.totalPlays}', 'Plays'),
          _statItem('${stats.daysUsingApp}', 'Days'),
          _statItem(stats.topArtist.isEmpty ? '-' : stats.topArtist, 'Top Artist',
              isText: true),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, {bool isText = false}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isText ? 12.sp : 22.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.white54),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 12.h),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgottenList(List<LyricsMemoryEntry> songs) {
    return SizedBox(
      height: 180.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return Container(
            width: 140.w,
            margin: EdgeInsets.only(right: 12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.white.withOpacity(0.3),
                      BlendMode.saturation,
                    ),
                    child: CachedNetworkImage(
                      imageUrl: song.imageUrl,
                      width: 140.w,
                      height: 140.w,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 140.w,
                        height: 140.w,
                        color: Colors.grey[800],
                        child: Icon(Icons.music_note, color: Colors.white38, size: 40.sp),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  song.title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${song.daysSinceLastPlayed} days ago',
                  style: TextStyle(fontSize: 10.sp, color: Colors.white38),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildJourneyTimeline(List<LyricsMemoryEntry> songs) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: songs.take(7).toList().asMap().entries.map((entry) {
          final song = entry.value;
          final isLast = entry.key == songs.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2.w,
                      height: 40.h,
                      color: AppColors.primaryColor.withOpacity(0.3),
                    ),
                ],
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.r),
                        child: CachedNetworkImage(
                          imageUrl: song.imageUrl,
                          width: 40.w,
                          height: 40.w,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 40.w,
                            height: 40.w,
                            color: Colors.grey[800],
                            child: Icon(Icons.music_note, color: Colors.white38, size: 18.sp),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
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
                            Text(
                              song.artist,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOnThisDayList(List<LyricsMemoryEntry> songs) {
    return SizedBox(
      height: 180.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          final yearsAgo = DateTime.now().difference(song.lastHeard).inDays ~/ 365;
          return Container(
            width: 160.w,
            margin: EdgeInsets.only(right: 12.w),
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: const Color(0xFFFFBE0B).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: const Color(0xFFFFBE0B).withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$yearsAgo year${yearsAgo > 1 ? 's' : ''} ago',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFFBE0B),
                  ),
                ),
                SizedBox(height: 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: CachedNetworkImage(
                    imageUrl: song.imageUrl,
                    width: 136.w,
                    height: 100.w,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 136.w,
                      height: 100.w,
                      color: Colors.grey[800],
                      child: Icon(Icons.music_note, color: Colors.white38, size: 30.sp),
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  song.title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.artist,
                  style: TextStyle(fontSize: 10.sp, color: Colors.white54),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
