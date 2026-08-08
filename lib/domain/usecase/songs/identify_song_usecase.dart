import 'package:dartz/dartz.dart';
import 'package:soundora/data/sources/audd/audd_data_source.dart';
import 'package:soundora/serviece_locator.dart';

import '../usecase.dart';

class IdentifySongUsecase implements Usecase<Either, String> {
  @override
  Future<Either> call({String? param}) async {
    try {
      if (param == null || param.isEmpty) {
        return const Left('No audio file provided');
      }
      final result = await getIt<AuddDataSource>().identifySong(param);
      if (result == null) {
        return const Left('Song not found');
      }
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
