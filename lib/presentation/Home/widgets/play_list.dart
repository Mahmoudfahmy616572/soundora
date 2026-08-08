import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/widgets/shimmer_widgets.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/presentation/Home/cubit/get_songs_cubit.dart';
import 'package:soundora/presentation/LikedSongs/cubit/favourite_songs_cubit.dart';
import 'package:soundora/presentation/LikedSongs/cubit/favourite_songs_state.dart';

import '../../songsPlayPage/songs_play_page.dart';
import '../cubit/get_songs_state.dart';

class GetPlayList extends StatefulWidget {
  const GetPlayList({super.key});

  @override
  State<GetPlayList> createState() => _GetPlayListState();
}

class _GetPlayListState extends State<GetPlayList> {
  late final GetSongsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = GetSongsCubit()..fetchSongs();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<GetSongsCubit, GetSongsState>(
        builder: (context, state) {
          if (state is GetSongsLoading) {
            return const Center(child: SongListShimmer());
          }
          if (state is GetSongsLoaded) {
            return Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Playlist",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22.sp,
                            color: const Color(0xFFDBDBDB)),
                      ),
                      Text(
                        "see more",
                        style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 12.sp,
                            color: const Color(0xFFC6C6C6)),
                      ),
                    ],
                  ),
                  Expanded(child: _playlist(state.songs, context)),
                ],
              ),
            );
          }
          if (state is GetSongsFailure) {
            return Center(
                child: Column(
              children: [
                Icon(
                  Icons.music_note_sharp,
                  size: 30.r,
                ),
                Text(state.errorMessage),
              ],
            ));
          }
          return const Text("SORRY TRY AGAIN LATER, UNKNOWN ERROR ");
        },
      ),
    );
  }

  Widget _playlist(List<SongModel> songs, BuildContext context) {
    return ListView.separated(
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final song = songs[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SongsPlayPage(
                    songs: songs,
                    index: index,
                    songModel: song,
                  ),
                ),
              );
            },
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CachedNetworkImage(
                        imageUrl: song.imageUrl,
                        width: 56.w,
                        height: 56.h,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 56.w,
                          height: 56.h,
                          color: Colors.grey[800],
                          child: const Icon(Icons.music_note, color: Colors.white54),
                        ),
                      ),
                      Container(
                        width: 30.w,
                        height: 30.h,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                      ),
                    ],
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
                          fontWeight: FontWeight.w700,
                          fontSize: 15.sp,
                          color: const Color(0xFFD6D6D6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        song.artist,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF969696),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                BlocBuilder<FavouriteSongsCubit, FavouriteSongsState>(
                  builder: (context, state) {
                    bool isFavourite =
                        context.watch<FavouriteSongsCubit>().isFavourite(song.id);
                    return IconButton(
                      onPressed: () {
                        context.read<FavouriteSongsCubit>().toggleFavourite(song);
                      },
                      icon: Icon(
                        isFavourite ? Icons.favorite : Icons.favorite_border,
                        color: isFavourite ? Colors.green : Colors.grey,
                        size: 20.sp,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
        separatorBuilder: (context, index) => SizedBox(height: 12.h),
        itemCount: songs.length);
  }
}
