import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundora/domain/usecase/songs/get_sound_dna_usecase.dart';
import 'package:soundora/serviece_locator.dart';

import 'sound_dna_state.dart';

class SoundDnaCubit extends Cubit<SoundDnaState> {
  final GetSoundDnaUsecase _getSoundDnaUsecase;
  SoundDnaCubit({GetSoundDnaUsecase? getSoundDnaUsecase})
      : _getSoundDnaUsecase =
            getSoundDnaUsecase ?? getIt<GetSoundDnaUsecase>(),
        super(SoundDnaInitial());

  Future<void> fetchSoundDna({
    required String title,
    required String artist,
  }) async {
    emit(SoundDnaLoading());
    final result = await _getSoundDnaUsecase.call(
      param: {'title': title, 'artist': artist},
    );
    result.fold(
      (failure) => emit(SoundDnaError(failure)),
      (features) => emit(SoundDnaLoaded(features)),
    );
  }

  void clearSoundDna() {
    emit(SoundDnaInitial());
  }
}
