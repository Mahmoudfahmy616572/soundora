import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/presentation/songsPlayPage/songs_play_page.dart';

class SmartChoiceSection extends StatelessWidget {
  final List<SongModel> forYou;
  final List<SongModel> topPlayed;
  final List<SongModel> similarSongs;
  final String similarBasedOn;
  final List<String> topGenres;
  final List<String> topArtists;

  const SmartChoiceSection({
    super.key,
    required this.forYou,
    this.topPlayed = const [],
    this.similarSongs = const [],
    this.similarBasedOn = '',
    this.topGenres = const [],
    this.topArtists = const [],
  });

  @override
  Widget build(BuildContext context) {
    final hasTaste = topGenres.isNotEmpty || topArtists.isNotEmpty;
    final hasAny = topPlayed.isNotEmpty ||
        similarSongs.isNotEmpty ||
        (hasTaste && forYou.isNotEmpty);
    if (!hasAny) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (topPlayed.isNotEmpty)
          _SongRow(
            icon: Icons.favorite,
            title: 'اللي بتحب تسمعه',
            subtitle: 'من سجل استماعك',
            songs: topPlayed,
          ),
        if (similarSongs.isNotEmpty)
          _SongRow(
            icon: Icons.auto_awesome,
            title: 'شبه اللي بتحب',
            subtitle: similarBasedOn,
            songs: similarSongs,
          ),
        if (hasTaste && forYou.isNotEmpty)
          _SongRow(
            icon: Icons.explore,
            title: 'من زوقك',
            subtitle: 'اختيارات تناسب ذوقك',
            songs: forYou,
          ),
      ],
    );
  }
}

class _SongRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<SongModel> songs;

  const _SongRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryColor, size: 20.sp),
              SizedBox(width: 6.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (subtitle.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 16.w, top: 4.h),
            child: Text(
              subtitle,
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
                child: _SongCard(song: song),
              );
            },
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
}

class _SongCard extends StatelessWidget {
  final SongModel song;

  const _SongCard({required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
