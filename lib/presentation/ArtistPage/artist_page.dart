import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/core/widgets/music_loading_widget.dart';
import 'package:soundora/data/sources/models/combined_artist_model.dart';
import 'package:soundora/presentation/ArtistPage/cubit/artist_details/artist_details_cubit.dart';
import 'package:soundora/presentation/ArtistPage/cubit/artist_details/artist_details_state.dart';

class ArtistPage extends StatelessWidget {
  final String artistName;
  final String? artistId;

  const ArtistPage({super.key, required this.artistName, this.artistId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ArtistDetailsCubit()
        ..fetchArtistDetails(artistName: artistName, artistId: artistId),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDarkTheme,
        body: BlocBuilder<ArtistDetailsCubit, ArtistDetailsState>(
          builder: (context, state) {
            if (state is ArtistDetailsLoading) {
              return const Center(
                child: MusicLoadingWidget(message: 'Loading artist...'),
              );
            }
            if (state is ArtistDetailsError) {
              return Center(
                child: Text(
                  state.errorMessage,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                ),
              );
            }
            if (state is ArtistDetailsLoaded) {
              return _buildArtistPage(context, state.artist);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildArtistPage(BuildContext context, CombinedArtistModel artist) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(artist),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),
                _buildArtistInfo(artist),
                SizedBox(height: 16.h),
                _buildStatsRow(artist),
                SizedBox(height: 24.h),
                if (artist.topTrackNames.isNotEmpty) ...[
                  _buildSectionTitle('Popular tracks'),
                  SizedBox(height: 12.h),
                  _buildTopTracks(artist),
                  SizedBox(height: 24.h),
                ],
                if (artist.biography != null && artist.biography!.isNotEmpty) ...[
                  _buildSectionTitle('About'),
                  SizedBox(height: 12.h),
                  _buildAboutSection(artist),
                  SizedBox(height: 24.h),
                ],
                if (artist.similarArtistNames.isNotEmpty) ...[
                  _buildSectionTitle('Fans also like'),
                  SizedBox(height: 12.h),
                  _buildSimilarArtists(artist),
                  SizedBox(height: 32.h),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildSliverAppBar(CombinedArtistModel artist) {
    return SliverAppBar(
      expandedHeight: 260.h,
      pinned: true,
      backgroundColor: AppColors.backgroundDarkTheme,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (artist.bannerUrl != null)
              CachedNetworkImage(
                imageUrl: artist.bannerUrl!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryColor, AppColors.backgroundDarkTheme],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryColor, AppColors.backgroundDarkTheme],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.backgroundDarkTheme.withOpacity(0.9),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16.h,
              left: 16.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (artist.genres.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        artist.genres.first,
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  SizedBox(height: 8.h),
                  Text(
                    artist.name,
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistInfo(CombinedArtistModel artist) {
    return Row(
      children: [
        if (artist.imageUrl != null)
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: artist.imageUrl!,
              width: 56.w,
              height: 56.h,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                width: 56.w,
                height: 56.h,
                color: Colors.grey[800],
                child: Icon(Icons.person, size: 28.sp, color: Colors.grey),
              ),
            ),
          ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                artist.name,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (artist.genres.isNotEmpty)
                Text(
                  artist.genres.join(', '),
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey[400],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(CombinedArtistModel artist) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        if (artist.followers != null)
          _buildStatItem(
            _formatNumber(artist.followers!),
            'Followers',
          ),
        if (artist.listeners != null)
          _buildStatItem(
            _formatNumber(artist.listeners!),
            'Listeners',
          ),
        if (artist.popularity != null)
          _buildStatItem(
            '${artist.popularity}',
            'Popularity',
          ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTopTracks(CombinedArtistModel artist) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: artist.topTrackNames.length > 5 ? 5 : artist.topTrackNames.length,
      separatorBuilder: (_, __) => SizedBox(height: 4.h),
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
          leading: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[500],
            ),
          ),
          title: Text(
            artist.topTrackNames[index],
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            artist.name,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
          ),
          trailing: Icon(
            Icons.play_circle_outline,
            color: AppColors.primaryLight,
            size: 26.sp,
          ),
          onTap: () {},
        );
      },
    );
  }

  Widget _buildAboutSection(CombinedArtistModel artist) {
    return Text(
      artist.biography!,
      style: TextStyle(
        fontSize: 14.sp,
        color: Colors.grey[300],
        height: 1.5,
      ),
      maxLines: 6,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSimilarArtists(CombinedArtistModel artist) {
    return SizedBox(
      height: 120.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: artist.similarArtistNames.length,
        separatorBuilder: (_, __) => SizedBox(width: 16.w),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArtistPage(
                    artistName: artist.similarArtistNames[index],
                  ),
                ),
              );
            },
            child: SizedBox(
              width: 80.w,
              child: Column(
                children: [
                  Container(
                    width: 64.w,
                    height: 64.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[800],
                    ),
                    child: Icon(
                      Icons.person,
                      size: 32.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    artist.similarArtistNames[index],
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
