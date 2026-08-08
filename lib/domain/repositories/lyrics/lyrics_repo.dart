import 'package:soundora/data/sources/lyrics/lyrics_data_source.dart';

abstract class LyricsRepository {
  Future<List<LyricLine>> fetchSyncedLyrics({
    required String trackName,
    required String artistName,
    String videoId = '',
    int durationSeconds = 0,
  });
}

class LyricsRepositoryImpl implements LyricsRepository {
  final LyricsDataSource _lyricsDataSource;

  LyricsRepositoryImpl({LyricsDataSource? lyricsDataSource})
      : _lyricsDataSource = lyricsDataSource ?? LyricsDataSourceImpl();

  @override
  Future<List<LyricLine>> fetchSyncedLyrics({
    required String trackName,
    required String artistName,
    String videoId = '',
    int durationSeconds = 0,
  }) async {
    return await _lyricsDataSource.fetchSyncedLyrics(
      trackName: trackName,
      artistName: artistName,
      videoId: videoId,
      durationSeconds: durationSeconds,
    );
  }
}
