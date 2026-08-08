import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/presentation/songsPlayPage/songs_play_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';

class NewReleasesWidget extends StatelessWidget {
  final List<SongModel> songs;
  const NewReleasesWidget({super.key, required this.songs});

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) return const SizedBox.shrink();
    final newSongs = songs.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'New Releases',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 190.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: newSongs.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final song = newSongs[index];
              return _buildReleaseCard(context, song, newSongs, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReleaseCard(BuildContext context, SongModel song, List<SongModel> allSongs, int index) {
    return GestureDetector(
      onTap: () {
        final playerCubit = context.read<SongPlayerCubit>();
        playerCubit.loadSong(allSongs, index, song.imageUrl);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SongsPlayPage(
              songModel: song,
              songs: allSongs,
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
                  top: 8.h,
                  left: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'NEW',
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
}
