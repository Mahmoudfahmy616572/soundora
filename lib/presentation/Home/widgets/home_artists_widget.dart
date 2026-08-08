import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/widgets/shimmer_widgets.dart';
import 'package:soundora/data/sources/deezer/deezer_data_source.dart';
import 'package:soundora/presentation/ArtistPage/artist_page.dart';
import 'package:soundora/serviece_locator.dart';

class HomeArtistsWidget extends StatefulWidget {
  const HomeArtistsWidget({super.key});

  @override
  State<HomeArtistsWidget> createState() => _HomeArtistsWidgetState();
}

class _HomeArtistsWidgetState extends State<HomeArtistsWidget> {
  List<_ArtistInfo> _artists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchArtists();
  }

  Future<void> _fetchArtists() async {
    final deezer = getIt<DeezerDataSource>();
    try {
      final tracks = await deezer.getTopTracks(limit: 50);
      final seen = <String>{};
      final artists = <_ArtistInfo>[];
      for (final track in tracks) {
        if (!seen.contains(track.artist)) {
          seen.add(track.artist);
          artists.add(_ArtistInfo(
            name: track.artist,
            imageUrl: track.imageUrl,
          ));
        }
        if (artists.length >= 10) break;
      }
      if (mounted) {
        setState(() {
          _artists = artists;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const HorizontalCardShimmer(cardWidth: 100, cardHeight: 80, circular: true);
    }
    if (_artists.isEmpty) {
      return const Center(
        child: Text('No artists available', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _artists.length,
      itemBuilder: (context, index) {
        final artist = _artists[index];
        return _ArtistCard(artist: artist);
      },
    );
  }
}

class _ArtistInfo {
  final String name;
  final String imageUrl;
  const _ArtistInfo({required this.name, required this.imageUrl});
}

class _ArtistCard extends StatelessWidget {
  final _ArtistInfo artist;
  const _ArtistCard({required this.artist});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArtistPage(artistName: artist.name),
          ),
        );
      },
      child: Container(
        width: 100.w,
        margin: EdgeInsets.only(right: 12.w),
        child: Column(
          children: [
            Container(
              width: 80.w,
              height: 80.h,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.hardEdge,
              child: CachedNetworkImage(
                imageUrl: artist.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child: Icon(Icons.person, color: Colors.white, size: 30.sp),
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              artist.name,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
