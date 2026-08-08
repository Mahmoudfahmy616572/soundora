import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/data/models/taste_profile/taste_profile.dart';
import 'package:soundora/data/sources/listening_history/listening_data_source.dart';
import 'package:soundora/presentation/TasteProfile/cubit/taste_profile_cubit.dart';

part 'smart_home_state.dart';

class SmartHomeCubit extends Cubit<SmartHomeState> {
  final TasteProfileCubit _tasteProfileCubit;

  SmartHomeCubit({
    required TasteProfileCubit tasteProfileCubit,
    ListeningDataSource? listeningDataSource,
  })  : _tasteProfileCubit = tasteProfileCubit,
        super(SmartHomeInitial());

  Future<void> loadPersonalizedContent({
    required List<SongModel> allNewSongs,
    required List<SongModel> allRecentlyPlayed,
  }) async {
    emit(SmartHomeLoading());

    try {
      final profile = _tasteProfileCubit.currentProfile;

      if (profile == null || profile.topGenres.isEmpty) {
        emit(SmartHomeContent(
          forYou: allNewSongs.take(6).toList(),
          newSongs: allNewSongs,
          recentlyPlayed: allRecentlyPlayed,
          basedOnGenre: const [],
          topGenres: const [],
          topArtists: const [],
        ));
        return;
      }

      final forYou = _rankSongsByTaste(allNewSongs, profile);
      final basedOnGenre = _filterByTopGenre(allNewSongs, profile);

      emit(SmartHomeContent(
        forYou: forYou,
        newSongs: allNewSongs,
        recentlyPlayed: allRecentlyPlayed,
        basedOnGenre: basedOnGenre,
        topGenres: profile.topGenres.take(3).toList(),
        topArtists: profile.topArtists.take(5).toList(),
      ));
    } catch (e) {
      emit(SmartHomeError('Failed to load personalized content'));
    }
  }

  List<SongModel> _rankSongsByTaste(List<SongModel> songs, TasteProfile profile) {
    final scored = songs.map((song) {
      double score = 0;

      final artistScore = profile.topArtists.indexOf(song.artist);
      if (artistScore >= 0) {
        score += (10 - artistScore).toDouble();
      }

      final lang = _detectLanguage(song.title, song.artist);
      if (lang == profile.primaryLanguage) {
        score += 3;
      }

      for (final genre in profile.topGenres) {
        if (song.title.toLowerCase().contains(genre) ||
            song.artist.toLowerCase().contains(genre)) {
          score += 2;
        }
      }

      return MapEntry(song, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(6).map((e) => e.key).toList();
  }

  List<SongModel> _filterByTopGenre(List<SongModel> songs, TasteProfile profile) {
    if (profile.topGenres.isEmpty) return songs.take(6).toList();

    final topGenre = profile.topGenres.first;
    final matches = songs.where((s) {
      final text = '${s.title} ${s.artist}'.toLowerCase();
      return text.contains(topGenre);
    }).toList();

    if (matches.length < 3) {
      return songs.take(6).toList();
    }
    return matches;
  }

  String _detectLanguage(String title, String artist) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    if (arabicRegex.hasMatch(title) || arabicRegex.hasMatch(artist)) return 'arabic';
    return 'english';
  }
}
