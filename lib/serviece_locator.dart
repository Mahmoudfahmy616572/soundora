import 'package:get_it/get_it.dart';
import 'package:soundora/data/repositories/auth/auth_repo_impl.dart';
import 'package:soundora/data/repositories/otp/otp_repo_impl.dart';
import 'package:soundora/data/sources/auth/auth_supabase_servieces.dart';
import 'package:soundora/data/sources/audd/audd_data_source.dart';
import 'package:soundora/data/sources/audiodb/audiodb_data_source.dart';
import 'package:soundora/data/sources/deezer/deezer_data_source.dart';
import 'package:soundora/data/sources/lastfm/lastfm_data_source.dart';
import 'package:soundora/data/sources/listening_history/genre_detector.dart';
import 'package:soundora/data/sources/listening_history/listening_data_source.dart';
import 'package:soundora/data/sources/lyrics/lyrics_data_source.dart';
import 'package:soundora/data/sources/music_iwant/music_iwant_data_source.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:soundora/data/sources/jamendo/jamendo_data_source.dart';
import 'package:soundora/data/sources/wolfxspotify/wolfxspotify_data_source.dart';
import 'package:soundora/domain/repositories/auth/auth_repo.dart';
import 'package:soundora/domain/repositories/lyrics/lyrics_repo.dart';
import 'package:soundora/domain/repositories/otp/otp_repo.dart';
import 'package:soundora/domain/usecase/auth/sighnup_usecase.dart';
import 'package:soundora/domain/usecase/otp/otp_usecase.dart';
import 'package:soundora/domain/usecase/songs/get_charts_usecase.dart';
import 'package:soundora/domain/usecase/songs/get_music_videos_usecase.dart';
import 'package:soundora/domain/usecase/songs/get_sound_dna_usecase.dart';
import 'package:soundora/domain/usecase/songs/get_artist_details_usecase.dart';
import 'package:soundora/domain/usecase/songs/identify_song_usecase.dart';
import 'package:soundora/domain/usecase/songs/get_songs_usecase.dart';
import 'package:soundora/domain/usecase/songs/search_songs_usecase.dart';
import 'package:soundora/presentation/DownloadedSongs/cubit/download_songs_for_offline_cubit.dart';
import 'package:soundora/presentation/Gamification/cubit/achievement_cubit.dart';
import 'package:soundora/presentation/Home/cubit/charts/charts_cubit.dart';
import 'package:soundora/presentation/Home/cubit/recently_played/recently_played_cubit.dart';
import 'package:soundora/presentation/LikedSongs/cubit/favourite_songs_cubit.dart';
import 'package:soundora/presentation/ListeningParty/cubit/listening_party_cubit.dart';
import 'package:soundora/presentation/LyricsMemory/cubit/lyrics_memory_cubit.dart';
import 'package:soundora/presentation/MainWrapper/cubit/cubit/navigation_cubit.dart';
import 'package:soundora/presentation/MoodMap/cubit/mood_map_cubit.dart';
import 'package:soundora/presentation/SearchPage/cubit/cubit/search_songs_cubit.dart';
import 'package:soundora/presentation/SmartDJ/cubit/smart_dj_cubit.dart';
import 'package:soundora/presentation/TimeMachine/cubit/time_machine_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/lyrics/lyrics_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/music_canvas/music_canvas_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/sound_dna/sound_dna_cubit.dart';
import 'package:soundora/presentation/LyricsEmotion/cubit/lyrics_emotion_cubit.dart';

import 'package:soundora/presentation/TasteProfile/cubit/taste_profile_cubit.dart';

import 'data/sources/songs/get_songs_supabase_servieces.dart';
import 'domain/usecase/auth/signin_usecase.dart';

final getIt = GetIt.instance;
Future<void> intializedDependences() async {
  // Auth
  getIt.registerSingleton<AuthSupabaseServieces>(AuthSupabaseServiecesImpl());
  getIt.registerSingleton<AuthRepo>(AuthRepoImpl());
  getIt.registerSingleton<SighnupUsecase>(SighnupUsecase());
  getIt.registerSingleton<SigninUsecase>(SigninUsecase());

  // OTP
  getIt.registerSingleton<OtpRepository>(OtpRepositoryImpl());
  getIt.registerSingleton<SendOtpUsecase>(SendOtpUsecase());
  getIt.registerSingleton<VerifyOtpUsecase>(VerifyOtpUsecase());

  // Songs (legacy)
  getIt.registerSingleton<SongsSupabaseServieces>(SongsSupabaseServiecesimpl());
  getIt.registerSingleton<GetSongsUsecase>(GetSongsUsecase());

  // Lyrics
  getIt.registerSingleton<LyricsDataSource>(LyricsDataSourceImpl());
  getIt.registerSingleton<LyricsRepository>(LyricsRepositoryImpl());

  // Deezer
  getIt.registerSingleton<DeezerDataSource>(DeezerDataSourceImpl());
  getIt.registerSingleton<SearchSongsUsecase>(SearchSongsUsecase());
  getIt.registerSingleton<GetChartsUsecase>(GetChartsUsecase());

  // TheAudioDB
  getIt.registerSingleton<AudioDbDataSource>(AudioDbDataSourceImpl());

  // wolfXspotify
  getIt.registerSingleton<WolfXSpotifyDataSource>(WolfXSpotifyDataSourceImpl());

  // Last.fm
  getIt.registerSingleton<LastFmDataSource>(LastFmDataSourceImpl());

  // Music I Want
  getIt.registerSingleton<MusicIWantDataSource>(MusicIWantDataSourceImpl());

  // AudD
  getIt.registerSingleton<AuddDataSource>(AuddDataSourceImpl());

  // Jamendo (full songs, Creative Commons)
  final jamendoClientId = dotenv.env['JAMENDO_CLIENT_ID'] ?? '';
  if (jamendoClientId.isNotEmpty) {
    getIt.registerSingleton<JamendoDataSource>(JamendoDataSourceImpl(clientId: jamendoClientId));
  }

  // Listening History (Milestone 1)
  getIt.registerSingleton<ListeningDataSource>(ListeningDataSourceImpl());
  getIt.registerSingleton<GenreDetector>(GenreDetector());

  // Feature Usecases
  getIt.registerSingleton<GetMusicVideosUsecase>(GetMusicVideosUsecase());
  getIt.registerSingleton<GetSoundDnaUsecase>(GetSoundDnaUsecase());
  getIt.registerSingleton<GetArtistDetailsUsecase>(GetArtistDetailsUsecase());
  getIt.registerSingleton<IdentifySongUsecase>(IdentifySongUsecase());

  // Cubits
  getIt.registerLazySingleton<LyricsCubit>(() => LyricsCubit());
  getIt.registerLazySingleton<SongPlayerCubit>(() => SongPlayerCubit(lyricsCubit: getIt<LyricsCubit>()));
  getIt.registerLazySingleton<FavouriteSongsCubit>(() => FavouriteSongsCubit()..fetchFavourites());
  getIt.registerLazySingleton<DownloadSongsForOfflineCubit>(() => DownloadSongsForOfflineCubit());
  getIt.registerLazySingleton<NavigationCubit>(() => NavigationCubit());
  getIt.registerLazySingleton<SearchSongsCubit>(() => SearchSongsCubit());
  getIt.registerLazySingleton<RecentlyPlayedCubit>(() => RecentlyPlayedCubit());
  getIt.registerLazySingleton<ChartsCubit>(() => ChartsCubit());

  // Taste Profile (Milestone 2)
  getIt.registerLazySingleton<TasteProfileCubit>(() => TasteProfileCubit()
    ..loadCachedProfile()
    ..analyzeTaste());

  // Premium Feature Cubits
  getIt.registerFactory<MoodMapCubit>(() => MoodMapCubit());
  getIt.registerLazySingleton<AchievementCubit>(() => AchievementCubit());
  getIt.registerFactory<SmartDJCubit>(() => SmartDJCubit());
  getIt.registerFactory<ListeningPartyCubit>(() => ListeningPartyCubit());
  getIt.registerFactory<TimeMachineCubit>(() => TimeMachineCubit());
  getIt.registerFactory<LyricsMemoryCubit>(() => LyricsMemoryCubit());

  // Now Playing Page Cubits
  getIt.registerFactory<MusicCanvasCubit>(() => MusicCanvasCubit());
  getIt.registerFactory<SoundDnaCubit>(() => SoundDnaCubit());
  getIt.registerFactory<LyricsEmotionCubit>(() => LyricsEmotionCubit(lyricsCubit: getIt<LyricsCubit>()));

  getIt<SongPlayerCubit>().onSongPlayed = (song) {
    getIt<RecentlyPlayedCubit>().addSong(song);
    getIt<AchievementCubit>().onSongPlayed(song);
  };
}
