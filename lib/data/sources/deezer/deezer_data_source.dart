import 'package:dio/dio.dart';
import 'package:soundora/data/models/songs/songs_model.dart';

import 'models/deezer_track_model.dart';

abstract class DeezerDataSource {
  Future<List<SongModel>> searchTracks(String query, {int offset = 0, int limit = 20});
  Future<List<SongModel>> getTopTracks({String country = 'eg', int limit = 25});
  Future<List<SongModel>> getEditorialTracks({int limit = 25});
  Future<List<SongModel>> getNewReleases({String country = 'eg', int limit = 25});
  Future<SongModel?> getTrack(int id);
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
}
