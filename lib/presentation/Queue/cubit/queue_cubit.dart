import 'package:bloc/bloc.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';

import 'queue_state.dart';

class QueueCubit extends Cubit<QueueState> {
  final SongPlayerCubit _playerCubit;
  QueueCubit(this._playerCubit) : super(QueueInitial());

  void loadQueue() {
    final playlist = _playerCubit.playList;
    final currentIndex = _playerCubit.currentIndex;
    if (playlist.isEmpty || currentIndex >= playlist.length - 1) {
      emit(QueueLoaded(upNext: [], currentPlayingIndex: currentIndex));
      return;
    }
    final upNext = playlist.sublist(currentIndex + 1);
    emit(QueueLoaded(upNext: upNext, currentPlayingIndex: currentIndex));
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (state is! QueueLoaded) return;
    final currentState = state as QueueLoaded;
    final playlist = _playerCubit.playList;
    final currentIndex = _playerCubit.currentIndex;

    final upNext = List<SongModel>.from(currentState.upNext);

    if (newIndex > oldIndex) newIndex -= 1;
    final item = upNext.removeAt(oldIndex);
    upNext.insert(newIndex, item);

    final newPlaylist = [
      ...playlist.sublist(0, currentIndex + 1),
      ...upNext,
    ];
    _playerCubit.updatePlaylist(newPlaylist);

    emit(currentState.copyWith(upNext: upNext));
  }

  void removeFromQueue(int index) {
    if (state is! QueueLoaded) return;
    final currentState = state as QueueLoaded;
    final upNext = List<SongModel>.from(currentState.upNext);
    upNext.removeAt(index);

    final playlist = _playerCubit.playList;
    final currentIndex = _playerCubit.currentIndex;
    final newPlaylist = [
      ...playlist.sublist(0, currentIndex + 1),
      ...upNext,
    ];
    _playerCubit.updatePlaylist(newPlaylist);

    emit(currentState.copyWith(upNext: upNext));
  }
}
