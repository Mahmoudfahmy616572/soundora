import 'package:dartz/dartz.dart';
import 'package:soundora/domain/usecase/usecase.dart';
import 'package:soundora/serviece_locator.dart';

import '../../../data/sources/songs/get_songs_supabase_servieces.dart';

class GetSongsUsecase implements Usecase<Either, void> {
  @override
  Future<Either> call({void param}) {
    return getIt<SongsSupabaseServieces>().getNewSongs();
  }
}
