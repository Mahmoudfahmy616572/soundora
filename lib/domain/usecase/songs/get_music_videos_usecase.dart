import 'package:dartz/dartz.dart';
import 'package:soundora/data/sources/audiodb/audiodb_data_source.dart';
import 'package:soundora/serviece_locator.dart';

import '../usecase.dart';

class GetMusicVideosUsecase implements Usecase<Either, String> {
  @override
  Future<Either> call({String? param}) async {
    try {
      final artistName = param ?? '';
      if (artistName.isEmpty) {
        return const Left('Artist name is required');
      }
      final videos = await getIt<AudioDbDataSource>().getMusicVideos(artistName);
      if (videos.isEmpty) {
        return const Left('No music videos found');
      }
      return Right(videos);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
