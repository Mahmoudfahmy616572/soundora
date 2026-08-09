import 'package:dartz/dartz.dart';
import 'package:soundora/data/sources/deezer/deezer_data_source.dart';
import 'package:soundora/data/sources/deezer/models/deezer_playlist_model.dart';
import 'package:soundora/serviece_locator.dart';

import '../usecase.dart';

class GetEditorialPicksUsecase implements Usecase<Either, dynamic> {
  @override
  Future<Either> call({dynamic param}) async {
    try {
      final deezer = getIt<DeezerDataSource>();
      final playlists = await deezer.getCuratedPlaylists(limit: 30);
      final curated = _pickCuratedPlaylist(playlists);
      if (curated == null) return Left('No curated playlist found');

      final songs = await deezer.getPlaylistTracks(curated.id, limit: 20);
      if (songs.isEmpty) return Left('Empty curated playlist');
      return Right(songs);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// Picks a genuinely curated playlist: skips country "Top ..." charts and
  /// prefers one with a decent track count.
  DeezerPlaylistModel? _pickCuratedPlaylist(List<DeezerPlaylistModel> playlists) {
    final candidates = playlists
        .where((p) => !_isChartPlaylist(p.title))
        .toList()
      ..sort((a, b) => b.trackCount.compareTo(a.trackCount));
    if (candidates.isEmpty) return null;
    return candidates.first;
  }

  bool _isChartPlaylist(String title) {
    final lower = title.toLowerCase();
    return lower.startsWith('top ') ||
        lower.contains('top 100') ||
        lower.contains('top 50');
  }
}
