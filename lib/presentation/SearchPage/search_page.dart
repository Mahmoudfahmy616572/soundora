import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/presentation/ArtistPage/artist_page.dart';
import 'package:soundora/presentation/CategoryPage/category_screen.dart';
import 'package:soundora/presentation/SearchPage/cubit/cubit/search_songs_cubit.dart';
import 'package:soundora/presentation/SearchPage/cubit/cubit/search_songs_state.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/songs_play_page.dart';
import 'package:soundora/presentation/SearchPage/cubit/identify_song/identify_song_cubit.dart';
import 'package:soundora/presentation/SearchPage/cubit/identify_song/identify_song_state.dart';
import 'package:permission_handler/permission_handler.dart';

class SearchPage extends StatefulWidget {
  final String? initialQuery;

  const SearchPage({super.key, this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  Timer? debounce;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showIdentifyResult = false;

  late final SearchSongsCubit _searchSongsCubit;
  late final IdentifySongCubit _identifySongCubit;

  static const List<Map<String, dynamic>> _quickCategories = [
    {'name': 'Pop', 'icon': Icons.star, 'color': Color(0xFFE91E63)},
    {'name': 'Hip Hop', 'icon': Icons.mic_external_on, 'color': Color(0xFFFF9800)},
    {'name': 'Rock', 'icon': Icons.electric_bolt, 'color': Color(0xFFF44336)},
    {'name': 'Quran', 'icon': Icons.menu_book, 'color': Color(0xFF4CAF50)},
    {'name': 'Electronic', 'icon': Icons.equalizer, 'color': Color(0xFF00BCD4)},
    {'name': 'Jazz', 'icon': Icons.piano, 'color': Color(0xFFFFC107)},
    {'name': 'R&B', 'icon': Icons.favorite, 'color': Color(0xFF7B1FA2)},
    {'name': 'Classical', 'icon': Icons.music_note, 'color': Color(0xFF607D8B)},
    {'name': 'Latin', 'icon': Icons.local_fire_department, 'color': Color(0xFFFF5722)},
    {'name': 'K-Pop', 'icon': Icons.auto_awesome, 'color': Color(0xFF3F51B5)},
  ];

  @override
  void initState() {
    super.initState();
    _searchSongsCubit = SearchSongsCubit();
    _identifySongCubit = IdentifySongCubit();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchSongsCubit.searchSongs(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchSongsCubit.close();
    _identifySongCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _searchSongsCubit),
        BlocProvider.value(value: _identifySongCubit),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                child: Text(
                  "Search",
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              _buildSearchField(),
              SizedBox(height: 12.h),
              BlocBuilder<IdentifySongCubit, IdentifySongState>(
                builder: (context, identifyState) {
                  if (identifyState is IdentifySongIdentified) {
                    return _buildIdentifyResult(context, identifyState);
                  }
                  return const SizedBox.shrink();
                },
              ),
              Expanded(
                child: BlocBuilder<SearchSongsCubit, SearchSongsState>(
                  builder: (context, state) {
                    if (state is SearchSongsLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                          strokeWidth: 2,
                        ),
                      );
                    }
                    if (state is SearchSongsLoaded) {
                      return NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollEndNotification &&
                              notification.metrics.pixels >=
                                  notification.metrics.maxScrollExtent - 200) {
                            context.read<SearchSongsCubit>().loadMore();
                          }
                          return false;
                        },
                        child: _buildSearchResults(state.songs, state.hasMore),
                      );
                    }
                    if (_searchController.text.isEmpty) {
                      return _buildIdleContent();
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return BlocBuilder<IdentifySongCubit, IdentifySongState>(
              builder: (context, identifyState) {
                final isListening = identifyState is IdentifySongListening;
                final isIdentifying = identifyState is IdentifySongIdentifying;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_showIdentifyResult)
                      Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: FloatingActionButton(
                          heroTag: 'clear_identify',
                          mini: true,
                          backgroundColor: Colors.grey[800],
                          onPressed: () {
                            context.read<IdentifySongCubit>().reset();
                            setState(() => _showIdentifyResult = false);
                          },
                          child: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    FloatingActionButton(
                      heroTag: 'identify_song',
                      backgroundColor: isListening ? Colors.red : AppColors.primaryColor,
                      onPressed: isIdentifying
                          ? null
                           : () async {
                              if (isListening) {
                                context.read<IdentifySongCubit>().identifySong('');
                                setState(() => _showIdentifyResult = true);
                                return;
                              }
                              final cubit = context.read<IdentifySongCubit>();
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              final status = await Permission.microphone.request();
                              if (!mounted) return;
                              if (status.isGranted) {
                                cubit.startListening();
                              } else {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Microphone permission is required to identify songs',
                                      style: TextStyle(fontSize: 14.sp, color: Colors.white),
                                    ),
                                    backgroundColor: const Color(0xFF1C1C2E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14.r),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                      child: isIdentifying
                          ? SizedBox(
                              width: 24.w,
                              height: 24.h,
                              child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(isListening ? Icons.stop : Icons.mic, color: Colors.white, size: 28.sp),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: TextStyle(color: Colors.white, fontSize: 15.sp),
          onChanged: (query) {
            if (debounce?.isActive ?? false) debounce!.cancel();
            if (query.trim().isEmpty) {
              _searchSongsCubit.searchSongs('');
              setState(() {});
              return;
            }
            debounce = Timer(const Duration(milliseconds: 500), () {
              _searchSongsCubit.searchSongs(query);
            });
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: "Songs, artists, podcasts...",
            hintStyle: TextStyle(color: Colors.white38, fontSize: 15.sp),
            prefixIcon: Icon(Icons.search, color: Colors.white54, size: 22.sp),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.white54, size: 20.sp),
                    onPressed: () {
                      _searchController.clear();
                      _searchSongsCubit.searchSongs('');
                      setState(() {});
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          ),
        ),
      ),
    );
  }

  Widget _buildIdleContent() {
    final recentSearches = _searchSongsCubit.recentSearches;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recentSearches.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _searchFocusNode.unfocus();
                  },
                  child: Text(
                    "See all",
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ...recentSearches.take(5).map((query) => _buildRecentItem(query)),
            SizedBox(height: 24.h),
          ],
          Text(
            "Browse all",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
              childAspectRatio: 1.6,
            ),
            itemCount: _quickCategories.length,
            itemBuilder: (context, index) {
              final cat = _quickCategories[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryScreen(
                        categoryName: cat['name'] as String,
                        categoryColor: cat['color'] as Color,
                        categoryIcon: cat['icon'] as IconData,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: (cat['color'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: (cat['color'] as Color).withOpacity(0.2),
                    ),
                  ),
                  padding: EdgeInsets.all(14.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 24.sp),
                      const Spacer(),
                      Text(
                        cat['name'] as String,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 100.h),
        ],
      ),
    );
  }

  Widget _buildRecentItem(String query) {
    return GestureDetector(
      onTap: () {
        _searchController.text = query;
        _searchSongsCubit.searchSongs(query);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.history, color: Colors.white38, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                query,
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<SongModel> songs, bool hasMore) {
    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, color: Colors.white24, size: 48.sp),
            SizedBox(height: 12.h),
            Text(
              "No results found",
              style: TextStyle(color: Colors.white54, fontSize: 15.sp),
            ),
          ],
        ),
      );
    }

    final playerCubit = context.read<SongPlayerCubit>();
    return ListView.builder(
      padding: EdgeInsets.only(top: 4.h, bottom: 100.h),
      itemCount: songs.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == songs.length) {
          return Padding(
            padding: EdgeInsets.all(16.r),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor, strokeWidth: 2),
            ),
          );
        }
        final song = songs[index];
        return _buildSongRow(song, songs, index, playerCubit);
      },
    );
  }

  Widget _buildSongRow(SongModel song, List<SongModel> allSongs, int index, SongPlayerCubit playerCubit) {
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
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10.r),
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
                  child: Icon(Icons.music_note, color: Colors.white38, size: 22.sp),
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
                  SizedBox(height: 3.h),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArtistPage(artistName: song.artist),
                        ),
                      );
                    },
                    child: Text(
                      song.artist,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(Icons.play_circle_outline_rounded, color: Colors.white38, size: 28.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentifyResult(BuildContext context, IdentifySongIdentified state) {
    final result = state.result;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8.r),
            ),
            clipBehavior: Clip.hardEdge,
            child: result.artworkUrl != null
                ? CachedNetworkImage(
                    imageUrl: result.artworkUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Icon(Icons.music_note, color: Colors.white54),
                  )
                : Icon(Icons.music_note, color: Colors.white54),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  result.title,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  result.artist,
                  style: TextStyle(fontSize: 12.sp, color: Colors.white54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.search, color: AppColors.primaryColor),
            onPressed: () {
              final query = '${result.title} ${result.artist}'.trim();
              _searchController.text = query;
              _searchSongsCubit.searchSongs(query);
              _identifySongCubit.reset();
              setState(() => _showIdentifyResult = false);
            },
          ),
        ],
      ),
    );
  }
}
