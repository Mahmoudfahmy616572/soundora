import 'package:dartz/dartz.dart';
import 'package:soundora/data/sources/lyrics/lyrics_data_source.dart';
import 'package:soundora/domain/repositories/lyrics/lyrics_repo.dart';
import 'package:soundora/serviece_locator.dart';

class LyricsParams {
  final String trackName;
  final String artistName;
  final String videoId;
  final int durationSeconds;
  LyricsParams({
    required this.trackName,
    required this.artistName,
    this.videoId = '',
    this.durationSeconds = 0,
  });
}

class FetchLyricsUsecase {
  Future<Either<String, List<LyricLine>>> call({
    required LyricsParams params,
  }) async {
    try {
      final lyricsRepo = getIt<LyricsRepository>();
      final lyrics = await lyricsRepo.fetchSyncedLyrics(
        trackName: params.trackName,
        artistName: params.artistName,
        videoId: params.videoId,
        durationSeconds: params.durationSeconds,
      );
      if (lyrics.isNotEmpty) {
        return Right(lyrics);
      }

      // Only real synced lyrics are shown. Fake timestamps spread over a
      // guessed duration never match the song, so they are worse than nothing.
      return const Left("No lyrics found");
    } catch (e) {
      return Left("Failed to fetch lyrics: $e");
    }
  }
}
