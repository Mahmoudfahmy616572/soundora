import 'package:bloc/bloc.dart';
import 'package:soundora/data/sources/deezer/deezer_data_source.dart';

import 'smart_dj_state.dart';

class SmartDJCubit extends Cubit<SmartDJState> {
  final DeezerDataSource _deezerDataSource;

  static const Map<SmartDJMode, Map<String, String>> _modeConfigs = {
    SmartDJMode.party: {
      'query': 'party hits dance club bangers',
      'name': 'Party Mix',
    },
    SmartDJMode.chill: {
      'query': 'chill lofi relaxing vibes',
      'name': 'Chill Vibes',
    },
    SmartDJMode.workout: {
      'query': 'workout gym motivation energy',
      'name': 'Workout Power',
    },
    SmartDJMode.sleep: {
      'query': 'sleep ambient piano calm',
      'name': 'Sleep Sounds',
    },
  };

  SmartDJCubit({DeezerDataSource? deezerDataSource})
      : _deezerDataSource = deezerDataSource ?? DeezerDataSourceImpl(),
        super(SmartDJInitial());

  void selectMode(SmartDJMode mode) async {
    emit(SmartDJLoading());
    try {
      final config = _modeConfigs[mode]!;
      final songs = await _deezerDataSource.searchTracks(config['query']!);
      emit(SmartDJLoaded(
        mode: mode,
        playlist: songs,
        playlistName: config['name']!,
      ));
    } catch (e) {
      emit(SmartDJFailure('Failed to generate playlist'));
    }
  }

  void refreshPlaylist() {
    if (state is SmartDJLoaded) {
      selectMode((state as SmartDJLoaded).mode);
    }
  }
}
