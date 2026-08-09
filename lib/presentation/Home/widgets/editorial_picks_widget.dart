import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/core/widgets/shimmer_widgets.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/presentation/Home/cubit/editorial_picks/editorial_picks_cubit.dart';
import 'package:soundora/presentation/Home/cubit/editorial_picks/editorial_picks_state.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/songs_play_page.dart';

class EditorialPicksWidget extends StatefulWidget {
  const EditorialPicksWidget({super.key});

  @override
  State<EditorialPicksWidget> createState() => _EditorialPicksWidgetState();
}

class _EditorialPicksWidgetState extends State<EditorialPicksWidget> {
  late final EditorialPicksCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = EditorialPicksCubit()..fetchEditorialPicks();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorialPicksCubit, EditorialPicksState>(
      bloc: _cubit,
      builder: (context, state) {
        if (state is EditorialPicksLoaded && state.songs.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_mosaic,
                        color: AppColors.primaryColor,
                        size: 18.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'اختيارات المحررين',
                        style: TextStyle(
                          fontSize: 19.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Satoshi',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'أغاني مختارة بعناية — مش الترند',
                    style: TextStyle(fontSize: 11.5.sp, color: Colors.white54),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            if (state is EditorialPicksLoading)
              const HorizontalCardShimmer(cardWidth: 140, cardHeight: 140)
            else if (state is EditorialPicksFailure)
              const SizedBox.shrink()
            else if (state is EditorialPicksLoaded && state.songs.isNotEmpty)
              SizedBox(
                height: 200.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: state.songs.length.clamp(0, 10),
                  itemBuilder: (context, index) {
                    final song = state.songs[index];
                    return _EditorialCard(
                      song: song,
                      allSongs: state.songs,
                      index: index,
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EditorialCard extends StatelessWidget {
  final SongModel song;
  final List<SongModel> allSongs;
  final int index;

  const _EditorialCard({
    required this.song,
    required this.allSongs,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final playerCubit = context.read<SongPlayerCubit>();
        playerCubit.loadSong(allSongs, index, song.imageUrl);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: playerCubit,
              child: SongsPlayPage(
                songModel: song,
                songs: allSongs,
                index: index,
              ),
            ),
          ),
        );
      },
      child: Container(
        width: 140.w,
        margin: EdgeInsets.only(right: 12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 140.w,
                  height: 140.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    color: Colors.grey[850],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: CachedNetworkImage(
                    imageUrl: song.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[800],
                      child: Icon(
                        Icons.music_note,
                        color: Colors.white38,
                        size: 40.sp,
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
                      color: AppColors.primaryColor,
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
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
