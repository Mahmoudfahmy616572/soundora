import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' show SizeExtension;
import 'package:soundora/common/backButton/back_button.dart';
import 'package:soundora/core/widgets/shimmer_widgets.dart';
import 'package:soundora/presentation/LikedSongs/cubit/favourite_songs_cubit.dart';
import 'package:soundora/presentation/LikedSongs/cubit/favourite_songs_state.dart';
import 'package:soundora/presentation/songsPlayPage/songs_play_page.dart';

class LikedsongsPage extends StatelessWidget {
  const LikedsongsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // appBar: BasicAppbar(
        //   title: Row(
        //     children: [
        //       Text("Liked Songs",
        //           style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold))
        //     ],
        //   ),
        // ),
        body: CustomScrollView(slivers: [
      _buildSliverAppBar(context),
      BlocBuilder<FavouriteSongsCubit, FavouriteSongsState>(
          builder: (context, state) {
        if (state is FavouriteSongsLoading) {
          return const SliverFillRemaining(
            child: SongListShimmer(),
          );
        } else if (state is FavouriteSongsLoaded) {
          final likedSongs = state.favouriteSongs;
          if (likedSongs.isEmpty) {
            return SliverFillRemaining(
              child: Center(
                child: Text(
                  "No liked songs yet!",
                  style: TextStyle(fontSize: 18.sp),
                ),
              ),
            );
          } else {
            return SliverList.builder(
                itemCount: likedSongs.length,
                itemBuilder: (context, index) {
                  final song = likedSongs[index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: CachedNetworkImage(
                        imageUrl: song.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.music_note),
                      ),
                    ),
                    title: Text(song.title,
                        style: TextStyle(
                            fontSize: 16.sp, fontWeight: FontWeight.w500)),
                    subtitle: Text(song.artist,
                        style: TextStyle(
                            fontSize: 14.sp, color: Colors.grey[600])),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SongsPlayPage(
                            songModel: song,
                            songs: likedSongs,
                            index: index,
                          ),
                        ),
                      );
                    },
                  );
                });
          }
        } else if (state is FavouriteSongsFailure) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                "Error loading liked songs",
                style: TextStyle(fontSize: 18.sp),
              ),
            ),
          );
        } else {
          return const SliverFillRemaining(
            child: Center(child: Text("No liked songs yet!")),
          );
        }
      })
    ]));
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120.h,
      pinned: true,
      leading: backButton(context),
      automaticallyImplyLeading: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff450af5), Color(0xffc4efd9)],
            ),
          ),
          child: Center(
            child: Text("Liked Songs",
                style: TextStyle(
                    fontSize: 30.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
