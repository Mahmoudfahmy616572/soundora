import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/data/models/taste_profile/taste_profile.dart';
import 'package:soundora/data/sources/listening_history/listening_data_source.dart';
import 'package:soundora/domain/usecase/songs/search_songs_usecase.dart';
import 'package:soundora/presentation/TasteProfile/cubit/taste_profile_cubit.dart';
import 'package:soundora/serviece_locator.dart';

part 'smart_search_state.dart';

class SmartSearchCubit extends Cubit<SmartSearchState> {
  final TasteProfileCubit _tasteProfileCubit;
  final ListeningDataSource _listeningDataSource;
  final SearchSongsUsecase _searchSongsUsecase;

  SmartSearchCubit({
    required TasteProfileCubit tasteProfileCubit,
    ListeningDataSource? listeningDataSource,
    SearchSongsUsecase? searchSongsUsecase,
  })  : _tasteProfileCubit = tasteProfileCubit,
        _listeningDataSource = listeningDataSource ?? ListeningDataSourceImpl(),
        _searchSongsUsecase = searchSongsUsecase ?? getIt<SearchSongsUsecase>(),
        super(SmartSearchInitial());

  List<String> get recentSearches => _listeningDataSource.getSearchHistory(limit: 10);

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      emit(SmartSearchInitial());
      return;
    }

    await _listeningDataSource.recordSearch(query);
    emit(SmartSearchLoading());

    final result = await _searchSongsUsecase.call(param: query);
    result.fold(
      (failure) => emit(SmartSearchError(failure)),
      (songs) {
        final profile = _tasteProfileCubit.currentProfile;
        if (profile != null) {
          final ranked = _rankByTaste(songs, profile);
          emit(SmartSearchLoaded(ranked, recentSearches: recentSearches));
        } else {
          emit(SmartSearchLoaded(songs, recentSearches: recentSearches));
        }
      },
    );
  }

  void clearRecentSearches() {
    _listeningDataSource.clearSearchHistory();
    emit(SmartSearchInitial());
  }

  List<SongModel> _rankByTaste(List<SongModel> songs, TasteProfile profile) {
    final scored = songs.map((song) {
      double score = 0;

      final artistIdx = profile.topArtists.indexOf(song.artist);
      if (artistIdx >= 0) {
        score += (10 - artistIdx).toDouble();
      }

      final lang = _detectLanguage(song.title, song.artist);
      if (lang == profile.primaryLanguage) {
        score += 2;
      }

      final stats = _listeningDataSource.getAllListenStats();
      final songStats = stats[song.id];
      if (songStats != null && songStats.isFavourite) {
        score += 5;
      }

      return MapEntry(song, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  String _detectLanguage(String title, String artist) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    if (arabicRegex.hasMatch(title) || arabicRegex.hasMatch(artist)) return 'arabic';
    return 'english';
  }
}
