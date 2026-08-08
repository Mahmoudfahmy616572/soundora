import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/core/widgets/shimmer_widgets.dart';
import 'package:soundora/serviece_locator.dart';
import 'package:soundora/data/sources/audiodb/audiodb_data_source.dart';
import 'package:soundora/data/sources/audiodb/models/audiodb_video_model.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeVideosWidget extends StatefulWidget {
  const HomeVideosWidget({super.key});

  @override
  State<HomeVideosWidget> createState() => _HomeVideosWidgetState();
}

class _HomeVideosWidgetState extends State<HomeVideosWidget> {
  List<AudioDbVideoModel> _videos = [];
  bool _isLoading = true;

  static const _popularArtists = [
    'Coldplay', 'Eminem', 'Drake', 'The Weeknd',
    'Ed Sheeran', 'Taylor Swift', 'Dua Lipa', 'Adele',
  ];

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    final audioDb = getIt<AudioDbDataSource>();
    final allVideos = <AudioDbVideoModel>[];
    for (final artist in _popularArtists) {
      try {
        final videos = await audioDb.getMusicVideos(artist);
        allVideos.addAll(videos);
      } catch (_) {}
      if (allVideos.length >= 10) break;
    }
    if (mounted) {
      setState(() {
        _videos = allVideos.take(15).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const HorizontalCardShimmer(cardWidth: 160, cardHeight: 90);
    }
    if (_videos.isEmpty) {
      return const Center(
        child: Text('No videos available', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return _VideoCard(video: video);
      },
    );
  }
}

class _VideoCard extends StatelessWidget {
  final AudioDbVideoModel video;
  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (video.youtubeId != null && video.youtubeId!.isNotEmpty) {
          final url = Uri.parse('https://www.youtube.com/watch?v=${video.youtubeId}');
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        width: 160.w,
        margin: EdgeInsets.only(right: 12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                color: Colors.grey[850],
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    color: Colors.grey[800],
                    child: Center(
                      child: Icon(Icons.play_circle_fill,
                          color: AppColors.primaryColor, size: 40.sp),
                    ),
                  ),
                  if (video.youtubeId != null)
                    Positioned(
                      bottom: 4.h,
                      right: 4.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text('YT',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              video.track,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              video.artist,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
