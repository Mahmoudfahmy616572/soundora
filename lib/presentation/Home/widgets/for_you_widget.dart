import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/presentation/songsPlayPage/songs_play_page.dart';

class ForYouWidget extends StatelessWidget {
  final List<SongModel> songs;
  final List<String> topGenres;

  const ForYouWidget({
    super.key,
    required this.songs,
    this.topGenres = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primaryColor, size: 20.sp),
              SizedBox(width: 6.w),
              Text(
                "For You",
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (topGenres.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 16.w, top: 4.h),
            child: Text(
              "Based on: ${topGenres.join(', ')}",
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white54,
              ),
            ),
          ),
        SizedBox(height: 10.h),
        SizedBox(
          height: 200.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            itemCount: songs.length,
            itemBuilder: (context, index) {
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
                child: Container(
                  width: 140.w,
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: CachedNetworkImage(
                          imageUrl: song.imageUrl,
                          width: 140.w,
                          height: 140.h,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 140.w,
                            height: 140.h,
                            color: Colors.grey[800],
                            child: const Icon(Icons.music_note, color: Colors.white54),
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
