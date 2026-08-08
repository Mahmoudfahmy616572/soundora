import 'package:dartz/dartz.dart';
import 'package:soundora/data/sources/music_iwant/music_iwant_data_source.dart';
import 'package:soundora/domain/usecase/usecase.dart';
import 'package:soundora/serviece_locator.dart';

class GetSoundDnaUsecase implements Usecase<Either, Map<String, String>> {
  @override
  Future<Either> call({Map<String, String>? param}) async {
    try {
      final title = param?['title'] ?? '';
      final artist = param?['artist'] ?? '';
      final features =
          await getIt<MusicIWantDataSource>().getSongFeatures(title, artist);
      if (features != null) {
        return Right(features);
      } else {
        return const Left('No sound DNA found for this song');
      }
    } catch (e) {
      return Left('Failed to fetch sound DNA: $e');
    }
  }
}
