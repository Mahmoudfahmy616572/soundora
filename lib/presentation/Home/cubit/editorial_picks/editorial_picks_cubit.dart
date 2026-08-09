import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundora/domain/usecase/songs/get_editorial_picks_usecase.dart';
import 'package:soundora/presentation/Home/cubit/editorial_picks/editorial_picks_state.dart';
import 'package:soundora/serviece_locator.dart';

class EditorialPicksCubit extends Cubit<EditorialPicksState> {
  final GetEditorialPicksUsecase _getEditorialPicksUsecase;
  EditorialPicksCubit({GetEditorialPicksUsecase? getEditorialPicksUsecase})
      : _getEditorialPicksUsecase =
            getEditorialPicksUsecase ?? getIt<GetEditorialPicksUsecase>(),
        super(EditorialPicksLoading());

  Future<void> fetchEditorialPicks() async {
    emit(EditorialPicksLoading());
    final result = await _getEditorialPicksUsecase.call();
    result.fold(
      (l) => emit(EditorialPicksFailure(l)),
      (songs) => emit(EditorialPicksLoaded(songs: songs)),
    );
  }
}
