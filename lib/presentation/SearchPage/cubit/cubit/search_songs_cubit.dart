import 'package:bloc/bloc.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/data/sources/listening_history/listening_data_source.dart';
import 'package:soundora/domain/usecase/songs/search_songs_usecase.dart';
import 'package:soundora/serviece_locator.dart';

import 'search_songs_state.dart';

class SearchSongsCubit extends Cubit<SearchSongsState> {
  final SearchSongsUsecase _searchSongsUsecase;
  final ListeningDataSource _listeningDataSource;

  String _currentQuery = '';
  int _currentOffset = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  static const int _pageSize = 20;

  SearchSongsCubit({
    SearchSongsUsecase? searchSongsUsecase,
    ListeningDataSource? listeningDataSource,
  })  : _searchSongsUsecase = searchSongsUsecase ?? getIt<SearchSongsUsecase>(),
        _listeningDataSource = listeningDataSource ?? getIt<ListeningDataSource>(),
        super(SearchSongsInitial());

  List<String> get recentSearches => _listeningDataSource.getSearchHistory(limit: 10);

  String get currentQuery => _currentQuery;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  void searchSongs(String query) async {
    if (query.trim().isEmpty) {
      emit(SearchSongsInitial());
      return;
    }

    _currentQuery = query;
    _currentOffset = 0;
    _hasMore = true;

    await _listeningDataSource.recordSearch(query);
    emit(SearchSongsLoading());

    final result = await _searchSongsUsecase.searchWithOffset(query, offset: 0, limit: _pageSize);
    result.fold(
      (l) => emit(SearchSongsError(l)),
      (songs) {
        final songList = songs as List<SongModel>;
        _hasMore = songList.length >= _pageSize;
        _currentOffset = songList.length;
        emit(SearchSongsLoaded(songs: songList, hasMore: _hasMore));
      },
    );
  }

  void loadMore() async {
    if (_isLoadingMore || !_hasMore || _currentQuery.isEmpty) return;

    _isLoadingMore = true;

    final result = await _searchSongsUsecase.searchWithOffset(
      _currentQuery,
      offset: _currentOffset,
      limit: _pageSize,
    );

    _isLoadingMore = false;

    result.fold(
      (l) {},
      (newSongs) {
        final newSongList = newSongs as List<SongModel>;
        if (newSongList.isEmpty) {
          _hasMore = false;
        } else {
          _hasMore = newSongList.length >= _pageSize;
          _currentOffset += newSongList.length;
        }

        final currentSongs = state is SearchSongsLoaded
            ? (state as SearchSongsLoaded).songs
            : <SongModel>[];

        emit(SearchSongsLoaded(
          songs: [...currentSongs, ...newSongList],
          hasMore: _hasMore,
        ));
      },
    );
  }
}
