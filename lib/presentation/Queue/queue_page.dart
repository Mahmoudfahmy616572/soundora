import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/services/offline_downloads.dart';
import 'package:soundora/presentation/DownloadedSongs/cubit/download_songs_for_offline_cubit.dart';
import 'package:soundora/presentation/DownloadedSongs/cubit/download_songs_for_offline_state.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/songs_play_page.dart';

import 'cubit/queue_cubit.dart';
import 'cubit/queue_state.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  @override
  void initState() {
    super.initState();
    context.read<QueueCubit>().loadQueue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Queue",
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<QueueCubit, QueueState>(
        builder: (context, state) {
          if (state is! QueueLoaded) {
            return const Center(child: Text("No songs in queue"));
          }
          if (state.upNext.isEmpty) {
            return const Center(
              child: Text(
                "No upcoming songs",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          return ReorderableListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            onReorder: (oldIndex, newIndex) {
              context.read<QueueCubit>().reorderQueue(oldIndex, newIndex);
            },
            itemCount: state.upNext.length,
            itemBuilder: (context, index) {
              final song = state.upNext[index];
              return Container(
                key: ValueKey(song.id + index.toString()),
                margin: EdgeInsets.only(bottom: 8.h),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: CachedNetworkImage(
                      imageUrl: song.imageUrl,
                      width: 48.w,
                      height: 48.h,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.music_note),
                    ),
                  ),
                  title: Text(
                    song.title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    song.artist,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BlocBuilder<DownloadSongsForOfflineCubit,
                          DownloadSongsForOfflineState>(
                        builder: (context, dlState) {
                          if (dlState is! DownloadSongsForOfflineLoaded) {
                            return const SizedBox.shrink();
                          }
                          final isDownloaded =
                              OfflineDownloads.syncPathOf(song.id) != null;
                          if (isDownloaded) {
                            return const Icon(Icons.download_done,
                                color: Colors.green, size: 20);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.drag_handle,
                        color: Colors.grey,
                        size: 20.sp,
                      ),
                    ],
                  ),
                  onTap: () {
                    final playerCubit = context.read<SongPlayerCubit>();
                    final fullPlaylist = playerCubit.playList;
                    final currentIdx = playerCubit.currentIndex;
                    final songIndex = currentIdx + 1 + index;
                    if (songIndex < fullPlaylist.length) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SongsPlayPage(
                            songModel: fullPlaylist[songIndex],
                            songs: fullPlaylist,
                            index: songIndex,
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
