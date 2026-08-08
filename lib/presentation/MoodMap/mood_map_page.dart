import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/core/widgets/shimmer_widgets.dart';
import 'package:soundora/presentation/MoodMap/cubit/mood_map_cubit.dart';
import 'package:soundora/presentation/MoodMap/cubit/mood_map_state.dart';
import 'package:soundora/presentation/songsPlayPage/songs_play_page.dart';

class MoodMapPage extends StatefulWidget {
  const MoodMapPage({super.key});

  @override
  State<MoodMapPage> createState() => _MoodMapPageState();
}

class _MoodMapPageState extends State<MoodMapPage> {
  String _selectedMood = 'Happy';

  final List<Map<String, dynamic>> _moods = [
    {'name': 'Happy', 'icon': Icons.sentiment_very_satisfied, 'color': Colors.amber},
    {'name': 'Sad', 'icon': Icons.sentiment_very_dissatisfied, 'color': Colors.blue},
    {'name': 'Energetic', 'icon': Icons.bolt, 'color': Colors.orange},
    {'name': 'Calm', 'icon': Icons.spa, 'color': Colors.teal},
    {'name': 'Focus', 'icon': Icons.psychology, 'color': Colors.purple},
    {'name': 'Party', 'icon': Icons.celebration, 'color': Colors.pink},
    {'name': 'Sleep', 'icon': Icons.nights_stay, 'color': Colors.indigo},
  ];

  @override
  void initState() {
    super.initState();
    context.read<MoodMapCubit>().selectMood(_selectedMood);
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
          'Mood Map',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 8.h),
          _buildMoodSelector(),
          SizedBox(height: 16.h),
          Expanded(child: _buildSongList()),
        ],
      ),
    );
  }

  Widget _buildMoodSelector() {
    return SizedBox(
      height: 90.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        scrollDirection: Axis.horizontal,
        itemCount: _moods.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          final mood = _moods[index];
          final isSelected = _selectedMood == mood['name'];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedMood = mood['name']);
              context.read<MoodMapCubit>().selectMood(mood['name']);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 72.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? (mood['color'] as Color).withOpacity(0.25)
                    : Colors.grey[900],
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isSelected
                      ? mood['color'] as Color
                      : Colors.grey[800]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    mood['icon'] as IconData,
                    color: isSelected ? mood['color'] as Color : Colors.grey,
                    size: 26.sp,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    mood['name'],
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSongList() {
    return BlocBuilder<MoodMapCubit, MoodMapState>(
      builder: (context, state) {
        if (state is MoodMapLoading) {
          return const SongListShimmer();
        }
        if (state is MoodMapFailure) {
          return Center(
            child: Text(
              state.message,
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
            ),
          );
        }
        if (state is MoodMapLoaded) {
          if (state.songs.isEmpty) {
            return Center(
              child: Text(
                'No songs found for this mood',
                style: TextStyle(color: Colors.grey, fontSize: 14.sp),
              ),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: state.songs.length,
            separatorBuilder: (_, __) => SizedBox(height: 8.h),
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
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: CachedNetworkImage(
                          imageUrl: song.imageUrl,
                          width: 50.w,
                          height: 50.w,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 50.w,
                            height: 50.w,
                            color: Colors.grey[800],
                            child: Icon(Icons.music_note, color: Colors.grey, size: 24.sp),
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
                                fontSize: 14.sp,
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
                                fontSize: 12.sp,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _getMoodIcon(_selectedMood),
                        color: _getMoodColor(_selectedMood).withOpacity(0.6),
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Color _getMoodColor(String mood) {
    return _moods.firstWhere(
      (m) => m['name'] == mood,
      orElse: () => {'color': AppColors.primaryColor},
    )['color'] as Color;
  }

  IconData _getMoodIcon(String mood) {
    return _moods.firstWhere(
      (m) => m['name'] == mood,
      orElse: () => {'icon': Icons.music_note},
    )['icon'] as IconData;
  }
}
