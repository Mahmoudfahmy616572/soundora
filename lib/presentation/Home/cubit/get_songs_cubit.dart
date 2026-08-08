import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundora/domain/usecase/songs/get_charts_usecase.dart';
import 'package:soundora/domain/usecase/songs/get_songs_usecase.dart';
import 'package:soundora/presentation/Home/cubit/get_songs_state.dart';
import 'package:soundora/serviece_locator.dart';

class GetSongsCubit extends Cubit<GetSongsState> {
  final GetChartsUsecase _getChartsUsecase;
  final GetSongsUsecase _getSongsUsecase;
  GetSongsCubit({GetChartsUsecase? getChartsUsecase, GetSongsUsecase? getSongsUsecase})
      : _getChartsUsecase = getChartsUsecase ?? getIt<GetChartsUsecase>(),
        _getSongsUsecase = getSongsUsecase ?? getIt<GetSongsUsecase>(),
        super(GetSongsLoading());

  Future<void> fetchSongs() async {
    emit(GetSongsLoading());

    final supabaseResult = await _getSongsUsecase.call();
    if (supabaseResult.isRight()) {
      final songs = supabaseResult.getOrElse(() => []);
      if (songs.isNotEmpty) {
        emit(GetSongsLoaded(songs: songs));
        return;
      }
    }

    var returnedSongs = await _getChartsUsecase.call(param: 'eg');
    returnedSongs.fold(
      (l) => emit(GetSongsFailure(l)),
      (data) => emit(GetSongsLoaded(songs: data)),
    );
  }
}
