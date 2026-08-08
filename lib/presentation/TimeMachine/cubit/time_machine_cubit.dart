import 'package:bloc/bloc.dart';
import 'package:soundora/data/sources/deezer/deezer_data_source.dart';
import 'package:soundora/data/models/songs/songs_model.dart';

import 'time_machine_state.dart';

class TimeMachineCubit extends Cubit<TimeMachineState> {
  final DeezerDataSource _deezerDataSource;

  static const Map<int, String> _decadeQueries = {
    1960: '60s classic hits',
    1970: '70s classic rock disco',
    1980: '80s synth pop new wave',
    1990: '90s grunge hip hop alternative',
    2000: '2000s pop r&b hits',
    2010: '2010s pop hits top charts',
    2020: '2020s trending pop hits',
  };

  TimeMachineCubit({DeezerDataSource? deezerDataSource})
      : _deezerDataSource = deezerDataSource ?? DeezerDataSourceImpl(),
        super(TimeMachineInitial());

  Future<void> loadOnThisDay() async {
    emit(TimeMachineLoading());
    try {
      final now = DateTime.now();
      final queries = [
        'top hits ${now.month} ${now.day}',
        'classic songs',
        'popular tracks',
      ];

      final List<SongModel> allSongs = [];
      for (final query in queries) {
        final songs = await _deezerDataSource.searchTracks(query);
        allSongs.addAll(songs);
        if (allSongs.length >= 15) break;
      }

      final uniqueSongs = <String, SongModel>{};
      for (final song in allSongs) {
        uniqueSongs[song.id] = song;
      }

      emit(OnThisDayLoaded(
        songs: uniqueSongs.values.toList(),
        day: now.day,
        month: now.month,
      ));
    } catch (e) {
      emit(TimeMachineFailure('Failed to load songs for this day'));
    }
  }

  Future<void> loadDecade(int decade) async {
    emit(TimeMachineLoading());
    try {
      final query = _decadeQueries[decade] ?? '$decade hits';
      final songs = await _deezerDataSource.searchTracks(query);
      emit(DecadeLoaded(songs: songs, decade: decade));
    } catch (e) {
      emit(TimeMachineFailure('Failed to load songs from the ${decade}s'));
    }
  }
}
