import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:soundora/common/appbar/basic_appbar.dart';
import 'package:soundora/core/config/assets/app_vectors.dart';
import 'package:soundora/presentation/Home/cubit/charts/charts_cubit.dart';
import 'package:soundora/presentation/Home/cubit/charts/charts_state.dart';
import 'package:soundora/presentation/Home/cubit/recently_played/recently_played_cubit.dart';
import 'package:soundora/presentation/Home/cubit/recently_played/recently_played_state.dart';
import 'package:soundora/presentation/Home/cubit/smart_home/smart_home_cubit.dart';
import 'package:soundora/presentation/Home/widgets/browse_categories_widget.dart';
import 'package:soundora/presentation/Home/widgets/continue_listening_widget.dart';
import 'package:soundora/presentation/Home/widgets/for_you_widget.dart';
import 'package:soundora/presentation/Home/widgets/hero_section.dart';
import 'package:soundora/presentation/Home/widgets/home_charts_widget.dart';
import 'package:soundora/presentation/Home/widgets/maqam_discover_widget.dart';
import 'package:soundora/presentation/Home/widgets/mood_activity_widget.dart';
import 'package:soundora/presentation/Home/widgets/new_releases_widget.dart';
import 'package:soundora/presentation/Home/widgets/podcasts_section_widget.dart';
import 'package:soundora/presentation/Home/widgets/trending_now_widget.dart';
import 'package:soundora/presentation/Home/widgets/your_artists_section.dart';
import 'package:soundora/presentation/Profile/profile_page.dart';
import 'package:soundora/presentation/TasteProfile/cubit/taste_profile_cubit.dart';
import 'package:soundora/serviece_locator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ChartsCubit _chartsCubit;
  late final SmartHomeCubit _smartHomeCubit;

  @override
  void initState() {
    super.initState();
    _chartsCubit = getIt<ChartsCubit>()..fetchCharts();
    _smartHomeCubit = SmartHomeCubit(
      tasteProfileCubit: context.read<TasteProfileCubit>(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recentState = context.read<RecentlyPlayedCubit>().state;
      final recentSongs = recentState is RecentlyPlayedLoaded
          ? recentState.songs
          : <dynamic>[];
      _smartHomeCubit.loadPersonalizedContent(
        allNewSongs: const [],
        allRecentlyPlayed: recentSongs.cast(),
      );
    });
  }

  @override
  void dispose() {
    _smartHomeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BasicAppbar(
        isLeading: true,
        title: SvgPicture.asset(
          AppVectors.logo,
          width: 108.w,
          height: 33.h,
          fit: BoxFit.fill,
        ),
        actions: IconButton(
          icon: const Icon(Icons.person, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _chartsCubit.fetchCharts();
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              const HeroSection(),
              SizedBox(height: 16.h),
              const MaqamDiscoverWidget(),
              SizedBox(height: 24.h),
              const ContinueListeningWidget(),
              SizedBox(height: 24.h),
              BlocBuilder<SmartHomeCubit, SmartHomeState>(
                bloc: _smartHomeCubit,
                builder: (context, state) {
                  if (state is SmartHomeContent && state.forYou.isNotEmpty) {
                    return ForYouWidget(
                      songs: state.forYou,
                      topGenres: state.topGenres,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              SizedBox(height: 24.h),
              const BrowseCategoriesWidget(),
              SizedBox(height: 24.h),
              const MoodActivityWidget(),
              SizedBox(height: 24.h),
              BlocBuilder<ChartsCubit, ChartsState>(
                bloc: _chartsCubit,
                builder: (context, state) {
                  if (state is ChartsLoaded && state.songs.isNotEmpty) {
                    return TrendingNowWidget(songs: state.songs);
                  }
                  return const SizedBox.shrink();
                },
              ),
              SizedBox(height: 24.h),
              BlocBuilder<ChartsCubit, ChartsState>(
                bloc: _chartsCubit,
                builder: (context, state) {
                  if (state is ChartsLoaded && state.songs.isNotEmpty) {
                    return NewReleasesWidget(songs: state.songs);
                  }
                  return const SizedBox.shrink();
                },
              ),
              SizedBox(height: 24.h),
              const PodcastsSectionWidget(),
              SizedBox(height: 24.h),
              const YourArtistsSection(),
              SizedBox(height: 24.h),
              BlocProvider.value(
                value: _chartsCubit,
                child: const HomeChartsWidget(),
              ),
              SizedBox(height: 100.h),
            ],
          ),
        ),
      ),
    );
  }
}
