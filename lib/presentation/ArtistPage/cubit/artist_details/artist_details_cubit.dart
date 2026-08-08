import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundora/domain/usecase/songs/get_artist_details_usecase.dart';
import 'package:soundora/presentation/ArtistPage/cubit/artist_details/artist_details_state.dart';
import 'package:soundora/serviece_locator.dart';

class ArtistDetailsCubit extends Cubit<ArtistDetailsState> {
  ArtistDetailsCubit() : super(ArtistDetailsInitial());

  Future<void> fetchArtistDetails({
    required String artistName,
    String? artistId,
  }) async {
    emit(ArtistDetailsLoading());
    final result = await getIt<GetArtistDetailsUsecase>().call(
      param: ArtistDetailsParam(artistName: artistName, artistId: artistId),
    );
    if (result != null) {
      emit(ArtistDetailsLoaded(artist: result));
    } else {
      emit(ArtistDetailsError('Failed to load artist details'));
    }
  }
}
