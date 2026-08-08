import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/core/widgets/shimmer_widgets.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/presentation/SearchPage/cubit/cubit/search_songs_cubit.dart';
import 'package:soundora/presentation/SearchPage/cubit/cubit/search_songs_state.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/songs_play_page.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryName;
  final Color categoryColor;
  final IconData categoryIcon;

  const CategoryScreen({
    super.key,
    required this.categoryName,
    this.categoryColor = AppColors.primaryColor,
    this.categoryIcon = Icons.music_note,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late final SearchSongsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SearchSongsCubit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cubit.searchSongs(widget.categoryName);
    });
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
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(
                child: BlocBuilder<SearchSongsCubit, SearchSongsState>(
                  builder: (context, state) {
                    if (state is SearchSongsLoading) {
                      return _buildLoading();
                    }
                    if (state is SearchSongsError) {
                      return _buildError(state.errorMessage);
                    }
                    if (state is SearchSongsLoaded) {
                      if (state.songs.isEmpty) {
                        return _buildEmpty();
                      }
                      return _buildGrid(state.songs, state.hasMore);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 16.h),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20.sp),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: widget.categoryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(widget.categoryIcon, color: widget.categoryColor, size: 24.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.categoryName,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Browse',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 0.75,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      itemBuilder: (context, index) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ShimmerWidget(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 12,
            ),
          ),
          SizedBox(height: 8.h),
          ShimmerWidget(width: 140.w, height: 13.h, borderRadius: 4),
          SizedBox(height: 6.h),
          ShimmerWidget(width: 90.w, height: 11.h, borderRadius: 4),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.white38, size: 48.sp),
          SizedBox(height: 12.h),
          Text(
            'Failed to load songs',
            style: TextStyle(color: Colors.white54, fontSize: 14.sp),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => _cubit.searchSongs(widget.categoryName),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.categoryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.categoryIcon, color: Colors.white24, size: 64.sp),
          SizedBox(height: 16.h),
          Text(
            'No songs found for ${widget.categoryName}',
            style: TextStyle(color: Colors.white54, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<SongModel> songs, bool hasMore) {
    final playerCubit = context.read<SongPlayerCubit>();
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 0.75,
      ),
      itemCount: songs.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == songs.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: CircularProgressIndicator(
                color: widget.categoryColor,
                strokeWidth: 2,
              ),
            ),
          );
        }
        final song = songs[index];
        return _buildSongCard(song, songs, index, playerCubit);
      },
    );
  }

  Widget _buildSongCard(SongModel song, List<SongModel> allSongs, int index, SongPlayerCubit playerCubit) {
    return GestureDetector(
      onTap: () {
        playerCubit.loadSong(allSongs, index, song.imageUrl);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SongsPlayPage(
              songModel: song,
              songs: allSongs,
              index: index,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: Colors.grey[850],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: CachedNetworkImage(
                    imageUrl: song.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[800],
                      child: Icon(Icons.music_note, color: Colors.white38, size: 40.sp),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8.h,
                  right: 8.w,
                  child: Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.categoryColor,
                      boxShadow: [
                        BoxShadow(
                          color: widget.categoryColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22.sp),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
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
              color: Colors.white54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
