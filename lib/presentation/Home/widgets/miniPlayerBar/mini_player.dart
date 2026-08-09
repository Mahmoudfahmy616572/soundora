import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_state.dart';
import 'package:soundora/presentation/songsPlayPage/songs_play_page.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  double _dragOffset = 0;
  bool _isDraggingDown = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SongPlayerCubit, SongPlayerState>(
      builder: (context, state) {
        if (state is! SongPlayerLoaded) {
          return const SizedBox.shrink();
        }
        if (state.playlist.isEmpty) {
          return const SizedBox.shrink();
        }

        if (state.currentIndex >= state.playlist.length ||
            state.currentIndex < 0) {
          return const SizedBox.shrink();
        }
        final song = state.playlist[state.currentIndex];
        final cubit = context.read<SongPlayerCubit>();
        return GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 0) {
              setState(() {
                _dragOffset += details.delta.dy;
                _isDraggingDown = true;
              });
            }
          },
          onVerticalDragEnd: (details) {
            final shouldDismiss = _isDraggingDown &&
                (_dragOffset > 80 ||
                    (details.primaryVelocity ?? 0) > 600);
            setState(() {
              _dragOffset = 0;
              _isDraggingDown = false;
            });
            if (shouldDismiss) {
              cubit.stopAndDismiss();
            }
          },
          onHorizontalDragEnd: (details) {
            if (_isDraggingDown) return;
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! < -200) {
              cubit.playNext();
            } else if (details.primaryVelocity! > 200) {
              cubit.playPrevious();
            }
          },
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SongsPlayPage(
                          songModel: song,
                          songs: state.playlist,
                          index: state.currentIndex,
                        )));
          },
          child: AnimatedContainer(
            duration: _isDraggingDown ? Duration.zero : const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(0, _dragOffset * 0.3, 0),
            height: 60.h,
            margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            decoration: BoxDecoration(
              color: const Color(0xff282828),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(5.r),
                  child: CachedNetworkImage(
                    imageUrl: song.imageUrl,
                    width: 45.w,
                    height: 45.h,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.music_note),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${song.title} - ${song.artist}",
                          style: TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: state.isFullSong
                              ? Colors.greenAccent.withOpacity(0.15)
                              : Colors.orangeAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4.r),
                          border: Border.all(
                            color: state.isFullSong
                                ? Colors.greenAccent.withOpacity(0.4)
                                : Colors.orangeAccent.withOpacity(0.4),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          state.isFullSong ? 'FULL' : '30s',
                          style: TextStyle(
                            fontSize: 7.sp,
                            fontWeight: FontWeight.w700,
                            color: state.isFullSong ? Colors.greenAccent : Colors.orangeAccent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                      cubit.audioPlayer.playing
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white),
                  onPressed: () => cubit.playOrpauseSong(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
