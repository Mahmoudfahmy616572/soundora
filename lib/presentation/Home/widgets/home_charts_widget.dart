import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/core/widgets/shimmer_widgets.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/presentation/Home/cubit/charts/charts_cubit.dart';
import 'package:soundora/presentation/Home/cubit/charts/charts_state.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/songs_play_page.dart';

class HomeChartsWidget extends StatefulWidget {
  const HomeChartsWidget({super.key});

  @override
  State<HomeChartsWidget> createState() => _HomeChartsWidgetState();
}

class _HomeChartsWidgetState extends State<HomeChartsWidget> {
  @override
  void initState() {
    super.initState();
    final state = context.read<ChartsCubit>().state;
    if (state is! ChartsLoaded) {
      context.read<ChartsCubit>().fetchCharts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChartsCubit, ChartsState>(
      builder: (context, state) {
        if (state is ChartsLoading) {
          return const HorizontalCardShimmer(cardWidth: 140, cardHeight: 110);
        }
        if (state is ChartsFailure) {
          return const Center(
            child: Text('Failed to load charts',
                style: TextStyle(color: Colors.grey)),
          );
        }
        if (state is ChartsLoaded) {
          if (state.songs.isEmpty) {
            return const Center(
              child: Text('No charts available',
                  style: TextStyle(color: Colors.grey)),
            );
          }
          return SizedBox(
            height: 180.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: state.songs.length.clamp(0, 10),
              itemBuilder: (context, index) {
                final song = state.songs[index];
                return _ChartCard(
                  song: song,
                  rank: index + 1,
                  allSongs: state.songs,
                  index: index,
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  final SongModel song;
  final int rank;
  final List<SongModel> allSongs;
  final int index;

  const _ChartCard({
    required this.song,
    required this.rank,
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
                  height: 110.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: Colors.grey[850],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: CachedNetworkImage(
                    imageUrl: song.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.music_note, color: Colors.white),
                  ),
                ),
                Positioned(
                  top: 4.h,
                  left: 4.w,
                  child: Container(
                    width: 24.w,
                    height: 24.h,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              song.title,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              song.artist,
              style: TextStyle(
                fontSize: 10.sp,
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
