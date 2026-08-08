import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/data/sources/deezer/models/deezer_track_model.dart';
import 'package:soundora/data/sources/models/combined_artist_model.dart';
import 'package:soundora/domain/usecase/songs/get_artist_details_usecase.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';
import 'package:soundora/serviece_locator.dart';

class ArtistHubPage extends StatefulWidget {
  final String artistName;
  const ArtistHubPage({super.key, required this.artistName});

  @override
  State<ArtistHubPage> createState() => _ArtistHubPageState();
}

class _ArtistHubPageState extends State<ArtistHubPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  CombinedArtistModel? _artist;
  List<SongModel> _localSongs = [];
  List<_AlbumGroup> _albums = [];
  bool _loadingDetails = true;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _load();
  }

  Future<void> _load() async {
    final cubit = context.read<SongPlayerCubit>();
    _localSongs = cubit.playList
        .where((s) =>
            s.artist.toLowerCase().trim() == widget.artistName.toLowerCase().trim())
        .toList();
    getIt<GetArtistDetailsUsecase>()
        .call(param: ArtistDetailsParam(artistName: widget.artistName))
        .then((artist) {
      if (mounted) setState(() { _artist = artist; _loadingDetails = false; });
    });
    _loadDeezerAlbums();
  }

  Future<void> _loadDeezerAlbums() async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ));
      final searchRes = await dio.get(
        'https://api.deezer.com/search',
        queryParameters: {
          'q': 'artist:"${widget.artistName}"',
          'limit': 50,
        },
      );
      final data = searchRes.data['data'] as List<dynamic>? ?? [];
      final tracks = data
          .map((j) => DeezerTrackModel.fromJson(j as Map<String, dynamic>))
          .where((t) => t.previewUrl.isNotEmpty)
          .toList();

      final groups = <String, _AlbumGroup>{};
      for (final t in tracks) {
        groups.putIfAbsent(t.albumTitle, () => _AlbumGroup(name: t.albumTitle, coverUrl: t.coverUrl, songs: []));
        groups[t.albumTitle]!.songs.add(t);
      }
      if (mounted) setState(() => _albums = groups.values.toList());
    } catch (_) {}
  }

  void _playSong(SongModel song) {
    final cubit = context.read<SongPlayerCubit>();
    final idx = cubit.playList.indexWhere((s) => s.id == song.id);
    if (idx >= 0) { cubit.loadSong(cubit.playList, idx, song.urlSongsbase); Navigator.pop(context); }
  }

  void _playDeezerTrack(DeezerTrackModel track) {
    final song = track.toSongModel();
    final cubit = context.read<SongPlayerCubit>();
    if (song.urlSongsbase.isNotEmpty) {
      cubit.loadSong([song], 0, song.urlSongsbase);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            if (_loadingDetails)
              const SliverToBoxAdapter(child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator())))
            else ...[
              SliverToBoxAdapter(child: _buildArtistInfo()),
              SliverToBoxAdapter(child: _buildStatsRow()),
              if (_albums.isNotEmpty) ...[
                SliverToBoxAdapter(child: _buildSectionTitle('Albums')),
                SliverToBoxAdapter(child: _buildAlbumStrip()),
              ],
              SliverToBoxAdapter(child: _buildSectionTitle('All Songs')),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, childAspectRatio: 0.75,
                    crossAxisSpacing: 12.w, mainAxisSpacing: 12.w,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _buildSongCard(_localSongs[i]),
                    childCount: _localSongs.length,
                  ),
                ),
              ),
            ],
            SliverPadding(padding: EdgeInsets.only(bottom: 40.h)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300.h, pinned: false, backgroundColor: Colors.black,
      leading: Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (_artist?.bannerUrl != null)
              CachedNetworkImage(imageUrl: _artist!.bannerUrl!, fit: BoxFit.cover, errorWidget: (a, b, c) => Container(color: Colors.grey[900]))
            else if (_artist?.imageUrl != null)
              CachedNetworkImage(imageUrl: _artist!.imageUrl!, fit: BoxFit.cover, errorWidget: (a, b, c) => Container(color: Colors.grey[900]))
            else
              Container(color: Colors.grey[900]),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.6), Colors.black],
                ),
              ),
            ),
            Positioned(
              bottom: 0, left: 24.w, right: 24.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _artist?.name ?? widget.artistName,
                    style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${_localSongs.length} songs',
                    style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.6)),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistInfo() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Row(
        children: [
          if (_artist?.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(60.r),
              child: CachedNetworkImage(
                imageUrl: _artist!.imageUrl!, width: 80.w, height: 80.w,
                fit: BoxFit.cover,
                errorWidget: (a, b, c) => Container(width: 80.w, height: 80.w, color: Colors.grey[800], child: Icon(Icons.person, color: Colors.grey[600], size: 40)),
              ),
            ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_artist?.genres != null && _artist!.genres.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Wrap(
                      spacing: 6.w,
                      children: _artist!.genres.take(3).map((g) => Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
                        child: Text(g, style: TextStyle(fontSize: 12.sp, color: Colors.white.withOpacity(0.7))),
                      )).toList(),
                    ),
                  ),
                if (_artist?.country != null)
                  Text(_artist!.country!, style: TextStyle(fontSize: 13.sp, color: Colors.white.withOpacity(0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final entries = <MapEntry<String, String>>[];
    if (_artist?.followers != null) entries.add(MapEntry('Followers', _formatNum(_artist!.followers!)));
    if (_artist?.listeners != null) entries.add(MapEntry('Listeners', _formatNum(_artist!.listeners!)));
    if (_artist?.popularity != null) entries.add(MapEntry('Popularity', '${_artist!.popularity}%'));
    if (entries.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Row(
        children: entries.map((e) => Expanded(
          child: Column(
            children: [
              Text(e.value, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(e.key, style: TextStyle(fontSize: 12.sp, color: Colors.white.withOpacity(0.5))),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 12.h),
      child: Text(title, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildAlbumStrip() {
    return SizedBox(
      height: 180.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _albums.length,
        separatorBuilder: (context, i) => SizedBox(width: 12.w),
        itemBuilder: (context, i) {
          final album = _albums[i];
          return GestureDetector(
            onTap: () => _showAlbumTracks(album),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: CachedNetworkImage(
                    imageUrl: album.coverUrl, width: 140.w, height: 140.w,
                    fit: BoxFit.cover,
                    errorWidget: (a, b, c) => Container(width: 140.w, height: 140.w, color: Colors.grey[800], child: Icon(Icons.album, color: Colors.grey[600], size: 50)),
                  ),
                ),
                SizedBox(height: 6.h),
                SizedBox(
                  width: 140.w,
                  child: Text(album.name, style: TextStyle(fontSize: 13.sp, color: Colors.white, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Text('${album.songs.length} tracks', style: TextStyle(fontSize: 11.sp, color: Colors.white.withOpacity(0.5))),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAlbumTracks(_AlbumGroup album) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: 400.h,
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            Container(width: 48.w, height: 4.h, margin: EdgeInsets.only(top: 12.h),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2.r))),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: CachedNetworkImage(imageUrl: album.coverUrl, width: 50.w, height: 50.w, fit: BoxFit.cover,
                      errorWidget: (a, b, c) => Container(width: 50.w, height: 50.w, color: Colors.grey[800])),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(child: Text(album.name, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white))),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: album.songs.length,
                separatorBuilder: (ctx, i) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
                itemBuilder: (ctx, i) {
                  final track = album.songs[i];
                  return ListTile(
                    dense: true,
                    leading: Text('${i + 1}', style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.5))),
                    title: Text(track.title, style: TextStyle(fontSize: 14.sp, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Icon(Icons.play_circle_outline, color: Colors.white.withOpacity(0.5), size: 20),
                    onTap: () => _playDeezerTrack(track),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongCard(SongModel song) {
    return GestureDetector(
      onTap: () => _playSong(song),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: CachedNetworkImage(
                imageUrl: song.imageUrl, fit: BoxFit.cover, width: double.infinity,
                errorWidget: (a, b, c) => Container(color: Colors.grey[900], child: Icon(Icons.music_note, color: Colors.grey[600], size: 40)),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(song.title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _AlbumGroup {
  final String name;
  final String coverUrl;
  final List<DeezerTrackModel> songs;
  _AlbumGroup({required this.name, required this.coverUrl, required this.songs});
}
