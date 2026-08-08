import 'package:bloc/bloc.dart';
import 'package:soundora/domain/usecase/songs/identify_song_usecase.dart';
import 'package:soundora/serviece_locator.dart';

import 'identify_song_state.dart';

class IdentifySongCubit extends Cubit<IdentifySongState> {
  final IdentifySongUsecase _identifySongUsecase;
  IdentifySongCubit({IdentifySongUsecase? identifySongUsecase})
      : _identifySongUsecase =
            identifySongUsecase ?? getIt<IdentifySongUsecase>(),
        super(IdentifySongInitial());

  void startListening() {
    emit(IdentifySongListening());
  }

  void identifySong(String audioFilePath) async {
    emit(IdentifySongIdentifying());

    final result =
        await _identifySongUsecase.call(param: audioFilePath);
    result.fold(
      (failure) {
        if (failure == 'Song not found') {
          emit(IdentifySongNotFound());
        } else {
          emit(IdentifySongError(failure));
        }
      },
      (song) => emit(IdentifySongIdentified(song)),
    );
  }

  void reset() {
    emit(IdentifySongInitial());
  }
}
