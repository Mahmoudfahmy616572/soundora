import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/core/widgets/music_loading_widget.dart';
import 'package:soundora/presentation/SmartDJ/cubit/smart_dj_cubit.dart';
import 'package:soundora/presentation/SmartDJ/cubit/smart_dj_state.dart';
import 'package:soundora/presentation/songsPlayPage/songs_play_page.dart';

class SmartDJPage extends StatefulWidget {
  const SmartDJPage({super.key});

  @override
  State<SmartDJPage> createState() => _SmartDJPageState();
}

class _SmartDJPageState extends State<SmartDJPage> {
  @override
  void initState() {
    super.initState();
    context.read<SmartDJCubit>().selectMode(SmartDJMode.party);
  }

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
          'Smart DJ',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<SmartDJCubit>().refreshPlaylist();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 8.h),
          _buildModeSelector(),
          SizedBox(height: 16.h),
          Expanded(child: _buildPlaylist()),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    final modes = [
      {'mode': SmartDJMode.party, 'icon': Icons.celebration, 'label': 'Party', 'color': Colors.pink},
      {'mode': SmartDJMode.chill, 'icon': Icons.spa, 'label': 'Chill', 'color': Colors.teal},
      {'mode': SmartDJMode.workout, 'icon': Icons.fitness_center, 'label': 'Workout', 'color': Colors.orange},
      {'mode': SmartDJMode.sleep, 'icon': Icons.nights_stay, 'label': 'Sleep', 'color': Colors.indigo},
    ];

    return SizedBox(
      height: 80.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        scrollDirection: Axis.horizontal,
        itemCount: modes.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          final m = modes[index];
          final mode = m['mode'] as SmartDJMode;
          return BlocBuilder<SmartDJCubit, SmartDJState>(
            buildWhen: (prev, curr) {
              if (prev is SmartDJLoaded && curr is SmartDJLoaded) {
                return prev.mode != curr.mode;
              }
              return true;
            },
            builder: (context, state) {
              final isSelected = state is SmartDJLoaded && state.mode == mode;
              return GestureDetector(
                onTap: () => context.read<SmartDJCubit>().selectMode(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 80.w,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (m['color'] as Color).withOpacity(0.25)
                        : Colors.grey[900],
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isSelected ? m['color'] as Color : Colors.grey[800]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        m['icon'] as IconData,
                        color: isSelected ? m['color'] as Color : Colors.grey,
                        size: 24.sp,
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        m['label'] as String,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPlaylist() {
    return BlocBuilder<SmartDJCubit, SmartDJState>(
      builder: (context, state) {
        if (state is SmartDJLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const MusicLoadingWidget(message: 'Generating your playlist...'),
                SizedBox(height: 16.h),
                Text(
                  'Generating your playlist...',
                  style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                ),
              ],
            ),
          );
        }
        if (state is SmartDJFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 40.sp),
                SizedBox(height: 12.h),
                Text(
                  state.message,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () => context.read<SmartDJCubit>().refreshPlaylist(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  ),
                ),
              ],
            ),
          );
        }
        if (state is SmartDJLoaded) {
          if (state.playlist.isEmpty) {
            return Center(
              child: Text(
                'No songs found',
                style: TextStyle(color: Colors.grey, fontSize: 14.sp),
              ),
            );
          }
          return Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor.withOpacity(0.3),
                      AppColors.primaryDark.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.queue_music, color: AppColors.primaryColor, size: 28.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.playlistName,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${state.playlist.length} songs',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.play_circle_fill, color: AppColors.primaryColor, size: 32.sp),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: state.playlist.length,
                  separatorBuilder: (_, __) => SizedBox(height: 6.h),
                  itemBuilder: (context, index) {
                    final song = state.playlist[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SongsPlayPage(
                              songModel: song,
                              songs: state.playlist,
                              index: index,
                            ),
                          ),
                        );
                      },
                      child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: CachedNetworkImage(
                              imageUrl: song.imageUrl,
                              width: 46.w,
                              height: 46.w,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                width: 46.w,
                                height: 46.w,
                                color: Colors.grey[800],
                                child: Icon(Icons.music_note, color: Colors.grey, size: 20.sp),
                              ),
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
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  song.artist,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
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
}
