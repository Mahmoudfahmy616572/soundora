import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundora/domain/usecase/songs/get_charts_usecase.dart';
import 'package:soundora/presentation/Home/cubit/charts/charts_state.dart';
import 'package:soundora/serviece_locator.dart';

class ChartsCubit extends Cubit<ChartsState> {
  final GetChartsUsecase _getChartsUsecase;
  ChartsCubit({GetChartsUsecase? getChartsUsecase})
      : _getChartsUsecase = getChartsUsecase ?? getIt<GetChartsUsecase>(),
        super(ChartsLoading());

  Future<void> fetchCharts({String country = 'eg'}) async {
    emit(ChartsLoading());
    final result = await _getChartsUsecase.call(param: country);
    result.fold(
      (l) => emit(ChartsFailure(l)),
      (songs) => emit(ChartsLoaded(songs: songs)),
    );
  }
}
