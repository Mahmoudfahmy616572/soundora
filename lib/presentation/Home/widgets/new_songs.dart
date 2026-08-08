import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:soundora/core/config/assets/app_vectors.dart';
import 'package:soundora/core/widgets/shimmer_widgets.dart';
import 'package:soundora/presentation/Home/cubit/get_songs_cubit.dart';
import 'package:soundora/presentation/Home/cubit/get_songs_state.dart';
import 'package:soundora/presentation/songsPlayPage/songs_play_page.dart';

import '../../../data/models/songs/songs_model.dart';

class NewSongs extends StatefulWidget {
  const NewSongs({super.key});

  @override
  State<NewSongs> createState() => _NewSongsState();
}

class _NewSongsState extends State<NewSongs> {
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
            return const HorizontalCardShimmer(cardWidth: 147, cardHeight: 185);
          }
          if (state is GetSongsLoaded) {
            final songs = state.songs;
            return _listSongs(songs);
          }
          if (state is GetSongsFailure) {
            return Center(child: Text(state.errorMessage));
          }
          return const SizedBox.shrink(
            child: Text("Unknown error"),
          );
        }));
  }

  Widget _listSongs(List<SongModel> songs) {
    return ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemBuilder: (context, index) => SizedBox(
              width: 147.w,
              height: 185.h,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SongsPlayPage(
                                songModel: songs[index],
                                songs: songs,
                                index: index,
                              )));
                },
                child: Column(children: [
                  Expanded(
                      child: Stack(
                    children: [
                      Hero(
                        tag: 'album_art_${songs[index].id}',
                        child: Container(
                          width: 147.w,
                          height: 185.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.r),
                            color: Colors.grey[300],
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: CachedNetworkImage(
                            width: 160.w,
                            imageUrl: songs[index].imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.music_note),
                            placeholder: (context, url) => ShimmerWidget(
                              height: 150.h,
                              width: 160.w,
                              borderRadius: 30,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 15.h,
                        right: 0.w,
                        child: Container(
                          width: 35.w,
                          height: 35.h,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xff959595)),
                          child: Padding(
                            padding: EdgeInsets.all(8.0.w),
                            child: SvgPicture.asset(
                              AppVectors.playMusicIcon,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
                  SizedBox(
                    height: 5.h,
                  ),
                  Text(
                    songs[index].title,
                    style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    songs[index].artist,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                ]),
              ),
            ),
        separatorBuilder: (context, index) => SizedBox(
              width: 14.w,
            ),
        itemCount: songs.length);
  }
}
