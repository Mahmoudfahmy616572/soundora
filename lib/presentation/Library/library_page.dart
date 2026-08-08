import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/common/appbar/basic_appbar.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/presentation/DownloadedSongs/downloaded_songs.dart';
import 'package:soundora/presentation/Home/cubit/recently_played/recently_played_cubit.dart';
import 'package:soundora/presentation/Home/cubit/recently_played/recently_played_state.dart';
import 'package:soundora/presentation/LikedSongs/liked_songs.dart'
    show LikedsongsPage;
import 'package:soundora/presentation/LikedSongs/cubit/favourite_songs_cubit.dart';
import 'package:soundora/presentation/LikedSongs/cubit/favourite_songs_state.dart';
import 'package:soundora/presentation/songsPlayPage/songs_play_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  void initState() {
    super.initState();
    context.read<FavouriteSongsCubit>().fetchFavourites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BasicAppbar(
        isLeading: true,
        title: Row(
          children: [
            Text(
              'Your Library',
              style: TextStyle(
                  fontSize: 27.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        children: [
          _listOfLikedSongs(context),
          _listOfDownloadedSongs(context),
          SizedBox(height: 24.h),
          _buildRecentlyPlayedSection(context),
          SizedBox(height: 24.h),
          _buildTopArtistsSection(context),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }
}

Widget _listOfLikedSongs(BuildContext context) {
  return ListTile(
    onTap: () {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => LikedsongsPage()));
    },
    contentPadding: EdgeInsets.zero,
    leading: Container(
      width: 50.w,
      height: 50.h,
      decoration: BoxDecoration(
          gradient:
              LinearGradient(colors: [Colors.deepPurple, Colors.blueAccent]),
          borderRadius: BorderRadius.circular(4.r)),
      child: Icon(Icons.favorite, color: Colors.white, size: 22.sp),
    ),
    title: Text("Liked Songs", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
    subtitle: BlocBuilder<FavouriteSongsCubit, FavouriteSongsState>(
        builder: (context, state) {
      int count = 0;
      if (state is FavouriteSongsLoaded) count = state.favouriteSongsIds.length;
      return Text("$count songs", style: TextStyle(fontSize: 14.sp, color: Colors.grey));
    }),
    trailing: Icon(Icons.chevron_right, color: Colors.grey),
  );
}

Widget _listOfDownloadedSongs(BuildContext context) {
  return ListTile(
    onTap: () {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => DownloadedsongsPage()));
    },
    contentPadding: EdgeInsets.zero,
    leading: Container(
      width: 50.w,
      height: 50.h,
      decoration: BoxDecoration(
          gradient:
              LinearGradient(colors: [Colors.teal, Colors.green]),
          borderRadius: BorderRadius.circular(4.r)),
      child: Icon(Icons.download_done, color: Colors.white, size: 22.sp),
    ),
    title: Text("Downloaded", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
    subtitle: Text("Available offline", style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
    trailing: Icon(Icons.chevron_right, color: Colors.grey),
  );
}

Widget _buildRecentlyPlayedSection(BuildContext context) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final cardWidth = (screenWidth * 0.28).clamp(96.0, 168.0);
  final imgSize = cardWidth;
  const gap = 6.0;
  const titleLine = 20.0;
  const artistLine = 18.0;
  final textBlock = gap + titleLine + artistLine;
  final listHeight = imgSize + textBlock + 4;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Recently Played",
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 12.h),
      BlocBuilder<RecentlyPlayedCubit, RecentlyPlayedState>(
        builder: (context, state) {
          if (state is RecentlyPlayedInitial) {
            return Center(
              child: SizedBox(
                height: 100.h,
                child: Text(
                  "Loading...",
                  style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                ),
              ),
            );
          }
          if (state is RecentlyPlayedLoaded && state.songs.isNotEmpty) {
            return SizedBox(
              height: listHeight,
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.2,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.songs.length,
                  separatorBuilder: (_, __) => SizedBox(width: 12.w),
                  itemBuilder: (context, index) {
                    final song = state.songs[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SongsPlayPage(
                              songModel: song,
                              songs: state.songs,
                              index: index,
                            ),
                          ),
                        );
                      },
                      child: SizedBox(
                        width: cardWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: CachedNetworkImage(
                                imageUrl: song.imageUrl,
                                width: cardWidth,
                                height: imgSize,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  width: cardWidth,
                                  height: imgSize,
                                  color: Colors.grey[800],
                                  child: Icon(Icons.music_note,
                                      color: Colors.white54, size: 30.sp),
                                ),
                              ),
                            ),
                            SizedBox(height: gap),
                            SizedBox(
                              height: titleLine,
                              child: Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: artistLine,
                              child: Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11.sp, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }
          return Container(
            height: 100.h,
            alignment: Alignment.center,
            child: Text(
              "No recently played songs",
              style: TextStyle(color: Colors.grey, fontSize: 14.sp),
            ),
          );
        },
      ),
    ],
  );
}

Widget _buildTopArtistsSection(BuildContext context) {
  return BlocBuilder<FavouriteSongsCubit, FavouriteSongsState>(
    builder: (context, state) {
      if (state is FavouriteSongsLoaded && state.favouriteSongs.isNotEmpty) {
        final artistMap = <String, SongModel>{};
        for (final song in state.favouriteSongs) {
          if (!artistMap.containsKey(song.artist)) {
            artistMap[song.artist] = song;
          }
        }
        final topArtists = artistMap.values.toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Artists",
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 130.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: topArtists.length,
                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                itemBuilder: (context, index) {
                  final song = topArtists[index];
                  return SizedBox(
                    width: 80.w,
                    child: Column(
                      children: [
                        Container(
                          width: 72.w,
                          height: 72.h,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: CachedNetworkImage(
                            imageUrl: song.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[800],
                              child: Icon(Icons.person, color: Colors.white54, size: 28.sp),
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }
      return const SizedBox.shrink();
    },
  );
}
