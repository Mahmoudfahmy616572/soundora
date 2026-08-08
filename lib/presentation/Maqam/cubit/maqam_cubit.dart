import 'package:bloc/bloc.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/data/sources/maqam/maqam_data_source.dart';

import 'maqam_state.dart';

class MaqamCubit extends Cubit<MaqamState> {
  final MaqamDataSource _dataSource;

  MaqamCubit({MaqamDataSource? dataSource})
      : _dataSource = dataSource ?? MaqamDataSourceImpl(),
        super(MaqamInitial());

  Future<void> loadMaqams() async {
    if (state is MaqamLoading || state is MaqamLoaded) return;
    emit(MaqamLoading());
    try {
      final grouped = await _dataSource.getSongsGroupedByMaqam();
      emit(MaqamLoaded(songsByMaqam: grouped));
    } catch (e) {
      emit(MaqamFailure('Failed to load the maqam catalog'));
    }
  }

  List<SongModel>? songsFor(String maqamKey) {
    final s = state;
    if (s is MaqamLoaded) return s.songsByMaqam[maqamKey];
    return null;
  }

  int songCount(String maqamKey) => songsFor(maqamKey)?.length ?? 0;
}
