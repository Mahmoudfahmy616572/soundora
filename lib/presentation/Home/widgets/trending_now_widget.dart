import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/presentation/songsPlayPage/songs_play_page.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TrendingNowWidget extends StatelessWidget {
  final List<SongModel> songs;
  const TrendingNowWidget({super.key, required this.songs});

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) return const SizedBox.shrink();
    final topSongs = songs.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Trending Now',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: topSongs.length,
          separatorBuilder: (_, __) => SizedBox(height: 4.h),
          itemBuilder: (context, index) {
            final song = topSongs[index];
            return _buildTrendingTile(context, song, index + 1, topSongs);
          },
        ),
      ],
    );
  }

  Widget _buildTrendingTile(BuildContext context, SongModel song, int rank, List<SongModel> allSongs) {
    return GestureDetector(
      onTap: () {
        final playerCubit = context.read<SongPlayerCubit>();
        playerCubit.loadSong(allSongs, rank - 1, song.imageUrl);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SongsPlayPage(
              songModel: song,
              songs: allSongs,
              index: rank - 1,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28.w,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? AppColors.primaryColor : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: 10.w),
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
                  child: Icon(Icons.music_note, color: Colors.white54, size: 20.sp),
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
            Icon(Icons.play_circle_outline, color: Colors.white38, size: 22.sp),
          ],
        ),
      ),
    );
  }
}
