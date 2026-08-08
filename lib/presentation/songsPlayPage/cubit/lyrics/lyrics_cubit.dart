import 'package:bloc/bloc.dart';
import 'package:soundora/domain/usecase/lyrics/fetch_lyrics_usecase.dart';

import 'lyrics_state.dart';

class LyricsCubit extends Cubit<LyricsState> {
  final FetchLyricsUsecase _fetchLyricsUsecase;
  LyricsCubit({FetchLyricsUsecase? fetchLyricsUsecase})
      : _fetchLyricsUsecase = fetchLyricsUsecase ?? FetchLyricsUsecase(),
        super(LyricsInitial());

  Future<void> fetchLyrics({
    required String trackName,
    required String artistName,
    String videoId = '',
    int durationSeconds = 0,
  }) async {
    emit(LyricsLoading());
    final result = await _fetchLyricsUsecase.call(
      params: LyricsParams(
        trackName: trackName,
        artistName: artistName,
        videoId: videoId,
        durationSeconds: durationSeconds,
      ),
    );
    result.fold(
      (failure) => emit(LyricsNotFound()),
      (lyrics) => emit(LyricsLoaded(lyrics)),
    );
  }

  void clearLyrics() {
    emit(LyricsInitial());
  }
}
