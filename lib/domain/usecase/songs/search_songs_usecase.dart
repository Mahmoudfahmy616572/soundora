import 'package:dartz/dartz.dart';
import 'package:soundora/data/sources/deezer/deezer_data_source.dart';
import 'package:soundora/serviece_locator.dart';

import '../usecase.dart';

class SearchSongsUsecase implements Usecase<Either, String> {
  @override
  Future<Either> call({String? param}) async {
    try {
      final query = param ?? '';
      final songs = await getIt<DeezerDataSource>().searchTracks(query);
      return Right(songs);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either> searchWithOffset(String query, {int offset = 0, int limit = 20}) async {
    try {
      final songs = await getIt<DeezerDataSource>().searchTracks(query, offset: offset, limit: limit);
      return Right(songs);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
