import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soundora/core/config/theme/app_theme.dart';
import 'package:soundora/core/services/offline_downloads.dart';
import 'package:soundora/core/services/resolved_url_cache.dart';
import 'package:soundora/core/services/sync_offset_cache.dart';
import 'package:soundora/data/sources/lyrics/lyrics_data_source.dart';
import 'package:soundora/presentation/DownloadedSongs/cubit/download_songs_for_offline_cubit.dart';
import 'package:soundora/presentation/Home/cubit/recently_played/recently_played_cubit.dart';
import 'package:soundora/presentation/LyricsEmotion/cubit/lyrics_emotion_cubit.dart';
import 'package:soundora/presentation/MainWrapper/cubit/cubit/navigation_cubit.dart';
import 'package:soundora/presentation/SearchPage/cubit/cubit/search_songs_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/lyrics/lyrics_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/music_canvas/music_canvas_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/sound_dna/sound_dna_cubit.dart';
import 'package:soundora/presentation/TasteProfile/cubit/taste_profile_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'presentation/LikedSongs/cubit/favourite_songs_cubit.dart'
    show FavouriteSongsCubit;
import 'presentation/splash/splash_screen.dart';
import 'serviece_locator.dart';

class NoOverscrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  await Hive.initFlutter();
  await Hive.openBox('offline_songs');
  await Hive.openBox('songs_metadata');
  await Hive.openBox('user_session');
  await Hive.openBox('recently_played');
  await Hive.openBox('lyrics_cache');
  await Hive.openBox('lyrics_memory');
  await Hive.openBox('search_history');
  await Hive.openBox('play_events');
  await Hive.openBox('skip_records');
  await Hive.openBox('listen_stats');
  await Hive.openBox('taste_profile');
  await Hive.openBox('achievements');

  // Best-effort housekeeping: expire old caches and migrate legacy downloads
  // without blocking the first frame.
  unawaited(_pruneAppCaches());

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory((await getTemporaryDirectory()).path),
  );
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.soundora.channel.audio',
    androidNotificationChannelName: 'Soundora playback',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );

  await intializedDependences();
  runApp(const MyApp());
}

/// Bounded cache cleanup + one-time migration, run in the background at launch.
Future<void> _pruneAppCaches() async {
  await ResolvedUrlCache.instance.purgeExpired();
  await SyncOffsetCache().purge();
  await LyricsDataSourceImpl.pruneCache();
  await OfflineDownloads.sweepExpired();
  await DownloadSongsForOfflineCubit.migrateLegacyDownloads();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<SongPlayerCubit>()),
        BlocProvider.value(value: getIt<FavouriteSongsCubit>()),
        BlocProvider.value(value: getIt<DownloadSongsForOfflineCubit>()),
        BlocProvider.value(value: getIt<NavigationCubit>()),
        BlocProvider.value(value: getIt<SearchSongsCubit>()),
        BlocProvider.value(value: getIt<LyricsCubit>()),
        BlocProvider.value(value: getIt<RecentlyPlayedCubit>()),
        BlocProvider.value(value: getIt<TasteProfileCubit>()),
        BlocProvider.value(value: getIt<MusicCanvasCubit>()),
        BlocProvider.value(value: getIt<LyricsEmotionCubit>()),
        BlocProvider.value(value: getIt<SoundDnaCubit>()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            scrollBehavior: NoOverscrollBehavior(),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
