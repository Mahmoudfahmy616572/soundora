import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundora/domain/usecase/songs/get_music_videos_usecase.dart';

import 'music_canvas_state.dart';

class MusicCanvasCubit extends Cubit<MusicCanvasState> {
  final GetMusicVideosUsecase _getMusicVideosUsecase;

  MusicCanvasCubit({GetMusicVideosUsecase? getMusicVideosUsecase})
      : _getMusicVideosUsecase = getMusicVideosUsecase ?? GetMusicVideosUsecase(),
        super(MusicCanvasInitial());

  Future<void> fetchMusicCanvas({required String artistName}) async {
    emit(MusicCanvasLoading());
    final result = await _getMusicVideosUsecase.call(param: artistName);
    result.fold(
      (failure) => emit(MusicCanvasError(failure)),
      (videos) {
        if (videos.isEmpty) {
          emit(MusicCanvasEmpty());
          return;
        }
        final video = videos.first;
        final url = video.videoUrl;
        if (url == null || url.isEmpty) {
          emit(MusicCanvasEmpty());
        } else {
          emit(MusicCanvasLoaded(
            videoUrl: url,
            youtubeId: video.youtubeId,
          ));
        }
      },
    );
  }

  void clearCanvas() {
    emit(MusicCanvasInitial());
  }
}
