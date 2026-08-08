import 'package:bloc/bloc.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/data/sources/deezer/deezer_data_source.dart';

import 'mood_map_state.dart';

class MoodMapCubit extends Cubit<MoodMapState> {
  final DeezerDataSource _deezerDataSource;

  static const Map<String, String> moodQueries = {
    'Happy': 'happy upbeat feel good',
    'Sad': 'sad emotional heartbreak',
    'Energetic': 'energetic workout intense',
    'Calm': 'calm relaxing peaceful',
    'Focus': 'focus concentration study',
    'Party': 'party dance club hits',
    'Sleep': 'sleep ambient lullaby',
  };

  MoodMapCubit({
    DeezerDataSource? deezerDataSource,
  })  : _deezerDataSource = deezerDataSource ?? DeezerDataSourceImpl(),
        super(MoodMapInitial());

  void selectMood(String mood) async {
    final currentState = state;
    if (currentState is MoodMapLoaded) {
      if (currentState.cachedMoods.containsKey(mood)) {
        emit(currentState.copyWith(
          selectedMood: mood,
          songs: currentState.cachedMoods[mood],
        ));
        return;
      }
    }

    emit(MoodMapLoading());
    try {
      final query = moodQueries[mood] ?? mood;
      final songs = await _deezerDataSource.searchTracks(query);

      final cachedMoods = <String, List<SongModel>>{};
      if (currentState is MoodMapLoaded) {
        cachedMoods.addAll(currentState.cachedMoods);
      }
      cachedMoods[mood] = songs;

      emit(MoodMapLoaded(
        selectedMood: mood,
        songs: songs,
        cachedMoods: cachedMoods,
      ));
    } catch (e) {
      emit(MoodMapFailure('Failed to load songs for $mood'));
    }
  }
}
