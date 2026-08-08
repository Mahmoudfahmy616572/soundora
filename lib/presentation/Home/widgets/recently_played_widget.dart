import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/presentation/Home/cubit/recently_played/recently_played_cubit.dart';
import 'package:soundora/presentation/Home/cubit/recently_played/recently_played_state.dart';
import 'package:soundora/presentation/songsPlayPage/songs_play_page.dart';

import '../../../core/config/theme/app_colors.dart';

class RecentlyPlayedWidget extends StatelessWidget {
  const RecentlyPlayedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecentlyPlayedCubit, RecentlyPlayedState>(
      builder: (context, state) {
        if (state is! RecentlyPlayedLoaded || state.songs.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recently Played",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context
                          .read<RecentlyPlayedCubit>()
                          .clearRecentlyPlayed();
                    },
                    child: Text(
                      "Clear",
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 150.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: state.songs.length,
                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                itemBuilder: (context, index) {
                  final song = state.songs[index];
                  return _buildRecentlyPlayedCard(context, song);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentlyPlayedCard(BuildContext context, SongModel song) {
    return GestureDetector(
      onTap: () {
        final allSongs = context.read<RecentlyPlayedCubit>().state
            is RecentlyPlayedLoaded
            ? (context.read<RecentlyPlayedCubit>().state as RecentlyPlayedLoaded)
                .songs
            : [song];
        final index = allSongs.indexWhere((s) => s.id == song.id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SongsPlayPage(
              songModel: song,
              songs: allSongs,
              index: index >= 0 ? index : 0,
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              width: 110.w,
              height: 108.h,
              decoration: BoxDecoration(
                color: Colors.grey[800],
              ),
              child: CachedNetworkImage(
                imageUrl: song.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    const Icon(Icons.music_note, color: Colors.white),
              ),
            ),
          ),
          SizedBox(height: 6.h),
          SizedBox(
            width: 110.w,
            child: Text(
              song.title,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          SizedBox(
            width: 110.w,
            child: Text(
              song.artist,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
