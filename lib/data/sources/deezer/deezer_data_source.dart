import 'package:dio/dio.dart';
import 'package:soundora/data/models/songs/songs_model.dart';

import 'models/deezer_playlist_model.dart';
import 'models/deezer_track_model.dart';

abstract class DeezerDataSource {
  Future<List<SongModel>> searchTracks(String query, {int offset = 0, int limit = 20});
  Future<List<SongModel>> getTopTracks({String country = 'eg', int limit = 25});
  Future<List<SongModel>> getEditorialTracks({int limit = 25});
  Future<List<SongModel>> getNewReleases({String country = 'eg', int limit = 25});
  Future<SongModel?> getTrack(int id);
  Future<List<DeezerPlaylistModel>> getCuratedPlaylists({int limit = 20});
  Future<List<SongModel>> getPlaylistTracks(int playlistId, {int limit = 25});

  /// Resolves the Deezer artist id + name for a track id. Returns null if unknown.
  Future<DeezerArtistRef?> getTrackArtist(int trackId);

  /// Related (similar) artists, resolved purely by id — language-safe.
  Future<List<DeezerArtistRef>> getRelatedArtists(int artistId, {int limit = 5});

  /// Top tracks of an artist by id — language-safe.
  Future<List<SongModel>> getArtistTopTracks(int artistId, {int limit = 10});
}

/// Minimal artist reference returned by id-based lookups.
class DeezerArtistRef {
  final int id;
  final String name;

  const DeezerArtistRef({required this.id, required this.name});
}

class DeezerDataSourceImpl implements DeezerDataSource {
  final Dio _dio;
  static const String _baseUrl = 'https://api.deezer.com/2.0';

  DeezerDataSourceImpl() : _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  List<SongModel> _parseTracks(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    return data
        .map((track) => DeezerTrackModel.fromJson(track as Map<String, dynamic>))
        .where((t) => t.previewUrl.isNotEmpty)
        .map((t) => t.toSongModel())
        .toList();
  }

  @override
  Future<List<SongModel>> searchTracks(String query, {int offset = 0, int limit = 20}) async {
    try {
      final response = await _dio.get('/search', queryParameters: {
        'q': query,
        'limit': limit,
        'index': offset,
      });
      return _parseTracks(response.data);
    } on DioException {
      return [];
    }
  }

  @override
  Future<List<SongModel>> getTopTracks({String country = 'eg', int limit = 25}) async {
    try {
      final response = await _dio.get('/chart/$country/tracks', queryParameters: {'limit': limit});
      return _parseTracks(response.data);
    } on DioException {
      return [];
    }
  }

  @override
  Future<List<SongModel>> getEditorialTracks({int limit = 25}) async {
    try {
      final response = await _dio.get('/editorial/0/tracks', queryParameters: {'limit': limit});
      return _parseTracks(response.data);
    } on DioException {
      return [];
    }
  }

  @override
  Future<List<SongModel>> getNewReleases({String country = 'eg', int limit = 25}) async {
    try {
      final response = await _dio.get('/chart/$country', queryParameters: {'limit': limit});
      final chartData = response.data as Map<String, dynamic>;
      final tracksData = chartData['tracks'] as Map<String, dynamic>? ?? {};
      return _parseTracks(tracksData);
    } on DioException {
      return [];
    }
  }

  @override
  Future<SongModel?> getTrack(int id) async {
    try {
      final response = await _dio.get('/track/$id');
      final track = DeezerTrackModel.fromJson(response.data as Map<String, dynamic>);
      return track.toSongModel();
    } on DioException {
      return null;
    }
  }

  @override
  Future<List<DeezerPlaylistModel>> getCuratedPlaylists({int limit = 20}) async {
    try {
      final response = await _dio.get('/chart/0/playlists', queryParameters: {'limit': limit});
      final data = response.data?['data'] as List<dynamic>? ?? [];
      return data
          .map((p) => DeezerPlaylistModel.fromJson(p as Map<String, dynamic>))
          .where((p) => p.id > 0 && p.trackCount > 0)
          .toList();
    } on DioException {
      return [];
    }
  }

  @override
  Future<List<SongModel>> getPlaylistTracks(int playlistId, {int limit = 25}) async {
    try {
      final response = await _dio.get('/playlist/$playlistId/tracks', queryParameters: {'limit': limit});
      return _parseTracks(response.data);
    } on DioException {
      return [];
    }
  }

  @override
  Future<DeezerArtistRef?> getTrackArtist(int trackId) async {
    try {
      final response = await _dio.get('/track/$trackId');
      final artist = response.data?['artist'] as Map<String, dynamic>?;
      final id = artist?['id'] as int?;
      final name = artist?['name']?.toString() ?? '';
      if (id == null || id <= 0) return null;
      return DeezerArtistRef(id: id, name: name);
    } on DioException {
      return null;
    }
  }

  @override
  Future<List<DeezerArtistRef>> getRelatedArtists(int artistId, {int limit = 5}) async {
    try {
      final response = await _dio.get('/artist/$artistId/related', queryParameters: {'limit': limit});
      final data = response.data?['data'] as List<dynamic>? ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .map((a) => DeezerArtistRef(
                id: a['id'] as int? ?? 0,
                name: a['name']?.toString() ?? '',
              ))
          .where((a) => a.id > 0 && a.name.isNotEmpty)
          .toList();
    } on DioException {
      return [];
    }
  }

  @override
  Future<List<SongModel>> getArtistTopTracks(int artistId, {int limit = 10}) async {
    try {
      final response = await _dio.get('/artist/$artistId/top', queryParameters: {'limit': limit});
      return _parseTracks(response.data);
    } on DioException {
      return [];
    }
  }
}
