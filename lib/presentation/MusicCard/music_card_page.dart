import 'dart:io' show File;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_state.dart';

class MusicCardPage extends StatelessWidget {
  final SongModel? song;

  const MusicCardPage({super.key, this.song});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Music Card',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: BlocBuilder<SongPlayerCubit, SongPlayerState>(
        builder: (context, playerState) {
          final SongModel? currentSong = song ??
              (playerState is SongPlayerLoaded &&
                      playerState.playlist.isNotEmpty
                  ? playerState.playlist[playerState.currentIndex]
                  : null);
          return Center(
            child: currentSong != null
                ? _MusicCardPreview(song: currentSong)
                : _noSongPlaceholder(),
          );
        },
      ),
    );
  }

  Widget _noSongPlaceholder() {
    return Padding(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off, color: Colors.white24, size: 64.sp),
          SizedBox(height: 16.h),
          Text(
            'No song selected',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Play a song to create a shareable music card',
            style: TextStyle(fontSize: 14.sp, color: Colors.white38),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MusicCardPreview extends StatefulWidget {
  final SongModel song;

  const _MusicCardPreview({required this.song});

  @override
  State<_MusicCardPreview> createState() => _MusicCardPreviewState();
}

class _MusicCardPreviewState extends State<_MusicCardPreview> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          RepaintBoundary(
            key: _cardKey,
            child: _buildCard(),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveCard,
              icon: _isSaving
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_alt, color: Colors.white),
              label: Text(
                _isSaving ? 'Saving...' : 'Save & Share Card',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: 320.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1035), Color(0xFF0D0D0D)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20.r)),
                child: CachedNetworkImage(
                  imageUrl: widget.song.imageUrl,
                  width: 320.w,
                  height: 320.w,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 320.w,
                    height: 320.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryColor.withOpacity(0.5),
                          AppColors.primaryDark.withOpacity(0.5),
                        ],
                      ),
                    ),
                    child: Icon(Icons.music_note,
                        color: Colors.white, size: 80.sp),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF0D0D0D).withOpacity(0.9),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16.w,
                left: 16.w,
                right: 16.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            'NOW PLAYING',
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      widget.song.title,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      widget.song.artist,
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.music_note,
                        color: AppColors.primaryColor, size: 16.sp),
                    SizedBox(width: 6.w),
                    Text(
                      widget.song.duration,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Soundora',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    SvgIconPlaceholder(size: 14.sp),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCard() async {
    setState(() => _isSaving = true);
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null && mounted) {
          final tempDir = await getTemporaryDirectory();
          final file = File(
            '${tempDir.path}/music_card_${DateTime.now().millisecondsSinceEpoch}.png',
          ).writeAsBytes(byteData.buffer.asUint8List());

          if (!mounted) return;
          await Share.shareXFiles(
            [XFile((await file).path, mimeType: 'image/png')],
            text: '${widget.song.title} â€” ${widget.song.artist} on Soundora',
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Card saved to your device',
                  style: TextStyle(fontSize: 14.sp),
                ),
                backgroundColor: AppColors.primaryColor,
              ),
            );
          }
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save card',
              style: TextStyle(fontSize: 14.sp),
            ),
            backgroundColor: Colors.red[800],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class SvgIconPlaceholder extends StatelessWidget {
  final double size;

  const SvgIconPlaceholder({super.key, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.headphones, size: size, color: AppColors.primaryColor);
  }
}
