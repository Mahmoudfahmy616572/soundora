import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/presentation/Home/cubit/recently_played/recently_played_cubit.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/presentation/Home/cubit/recently_played/recently_played_state.dart';
import 'package:soundora/presentation/songsPlayPage/songs_play_page.dart';

class ContinueListeningWidget extends StatelessWidget {
  const ContinueListeningWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecentlyPlayedCubit, RecentlyPlayedState>(
      builder: (context, state) {
        if (state is! RecentlyPlayedLoaded || state.songs.isEmpty) {
          return const SizedBox.shrink();
        }
        final songs = state.songs.take(10).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Continue Listening', 'See all', null),
            SizedBox(height: 12.h),
            SizedBox(
              height: 200.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: songs.length,
                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                itemBuilder: (context, index) => _buildCard(context, songs, index),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, List<SongModel> songs, int index) {
    final song = songs[index];
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SongsPlayPage(
              songModel: song,
              songs: songs,
              index: index,
            ),
          ),
        );
      },
      child: SizedBox(
        width: 140.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 140.w,
                  height: 140.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: Colors.grey[850],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: CachedNetworkImage(
                    imageUrl: song.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[800],
                      child: Icon(Icons.music_note, color: Colors.white38, size: 40.sp),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8.h,
                  right: 8.w,
                  child: Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.7),
                    ),
                    child: Icon(Icons.play_arrow, color: Colors.white, size: 18.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
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
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSectionHeader(String title, String action, VoidCallback? onTap) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (action.isNotEmpty)
            GestureDetector(
              onTap: onTap,
              child: Text(
                action,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
