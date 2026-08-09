import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/common/appbar/basic_appbar.dart';
import 'package:soundora/core/config/assets/app_vectors.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/presentation/Home/cubit/charts/charts_cubit.dart';
import 'package:soundora/presentation/Home/cubit/charts/charts_state.dart';
import 'package:soundora/presentation/Home/cubit/recently_played/recently_played_cubit.dart';
import 'package:soundora/presentation/Home/cubit/recently_played/recently_played_state.dart';
import 'package:soundora/presentation/Home/cubit/smart_home/smart_home_cubit.dart';
import 'package:soundora/presentation/Home/widgets/continue_listening_widget.dart';
import 'package:soundora/presentation/Home/widgets/editorial_picks_widget.dart';
import 'package:soundora/presentation/Home/widgets/hero_section.dart';
import 'package:soundora/presentation/Home/widgets/home_charts_widget.dart';
import 'package:soundora/presentation/Home/widgets/maqam_discover_widget.dart';
import 'package:soundora/presentation/Home/widgets/mood_activity_widget.dart';
import 'package:soundora/presentation/Home/widgets/quick_access_widget.dart';
import 'package:soundora/presentation/Home/widgets/smart_choice_section.dart';
import 'package:soundora/presentation/MainWrapper/cubit/cubit/navigation_cubit.dart';
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
  List<SongModel> _lastPool = const [];
  StreamSubscription<int>? _navSub;
  StreamSubscription<ChartsState>? _chartsSub;
  bool _subscribed = false;
  bool _refreshing = false;
  int _lastNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _chartsCubit = getIt<ChartsCubit>();
    _smartHomeCubit = SmartHomeCubit(
      tasteProfileCubit: context.read<TasteProfileCubit>(),
    );

    _chartsSub = _chartsCubit.stream.listen((state) {
      if (state is ChartsLoaded) _lastPool = state.songs;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshHome();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subscribed) return;
    _subscribed = true;
    _navSub = context.read<NavigationCubit>().stream.listen((index) {
      if (index == 0 && _lastNavIndex != 0 && !_refreshing) {
        _refreshHome();
      }
      _lastNavIndex = index;
    });
  }

  /// Refreshes charts + taste + smart recommendations.
  /// Never hangs: on charts failure/timeout it falls back to the last
  /// known pool so the pull-to-refresh indicator always completes.
  Future<void> _refreshHome() async {
    try {
      _chartsCubit.fetchCharts();

      try {
        await context
            .read<TasteProfileCubit>()
            .analyzeTaste()
            .timeout(const Duration(seconds: 6));
      } catch (_) {}

      final chartsState = await _waitForChartsLoaded();
      if (chartsState is ChartsLoaded) _lastPool = chartsState.songs;

      if (!mounted) return;
      final recentState = context.read<RecentlyPlayedCubit>().state;
      final recentSongs = recentState is RecentlyPlayedLoaded
          ? recentState.songs
          : <dynamic>[];
      await _smartHomeCubit.loadPersonalizedContent(
        allNewSongs: _lastPool,
        allRecentlyPlayed: recentSongs.cast(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('تم تحديث التوصيات'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } catch (e, st) {
      debugPrint('[Home] _refreshHome ERROR: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('حصل خطأ أثناء التحديث'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }
  }

  Future<ChartsState> _waitForChartsLoaded() async {
    if (_chartsCubit.state is ChartsLoaded) return _chartsCubit.state;
    try {
      return await _chartsCubit.stream
          .where((s) => s is ChartsLoaded)
          .timeout(const Duration(seconds: 8))
          .first;
    } catch (e) {
      debugPrint('[Home] _waitForChartsLoaded timed out, using current state');
      return _chartsCubit.state;
    }
  }

  @override
  void dispose() {
    _navSub?.cancel();
    _chartsSub?.cancel();
    _smartHomeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BasicAppbar(
        isLeading: true,
        title: Image.asset(
          AppVectors.logo,
          height: 33.h,
        ),
        actions: Row(
          children: [
            IconButton(
              icon: _refreshing
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshing
                  ? null
                  : () async {
                      setState(() => _refreshing = true);
                      await _refreshHome();
                      if (mounted) setState(() => _refreshing = false);
                    },
            ),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () {
          return _refreshHome();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              const HeroSection(),
              SizedBox(height: 20.h),
              const QuickAccessWidget(),
              SizedBox(height: 24.h),
              const MaqamDiscoverWidget(),
              SizedBox(height: 24.h),
              const ContinueListeningWidget(),
              SizedBox(height: 24.h),
              BlocBuilder<SmartHomeCubit, SmartHomeState>(
                bloc: _smartHomeCubit,
                builder: (context, state) {
                  if (state is SmartHomeContent) {
                    return SmartChoiceSection(
                      forYou: state.forYou,
                      topPlayed: state.topPlayed,
                      similarSongs: state.similarSongs,
                      similarBasedOn: state.similarBasedOn,
                      topGenres: state.topGenres,
                      topArtists: state.topArtists,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              SizedBox(height: 24.h),
              const MoodActivityWidget(),
              SizedBox(height: 24.h),
              const EditorialPicksWidget(),
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
