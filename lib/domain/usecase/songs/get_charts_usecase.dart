import 'package:dartz/dartz.dart';
import 'package:soundora/data/sources/deezer/deezer_data_source.dart';
import 'package:soundora/serviece_locator.dart';

import '../usecase.dart';

class GetChartsUsecase implements Usecase<Either, String> {
  @override
  Future<Either> call({String? param}) async {
    try {
      final country = param ?? 'eg';
      final songs = await getIt<DeezerDataSource>().getTopTracks(country: country, limit: 25);
      return Right(songs);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
