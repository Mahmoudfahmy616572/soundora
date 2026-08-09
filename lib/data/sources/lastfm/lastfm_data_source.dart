import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/lastfm_track_model.dart';
import 'models/lastfm_artist_model.dart';

abstract class LastFmDataSource {
  Future<List<LastFmTrackModel>> getSimilarTracks(String artist, String track, {int limit = 10});
  Future<LastFmArtistModel?> getArtistInfo(String artist);
  Future<List<LastFmTrackModel>> getArtistTopTracks(String artist, {int limit = 10});
}

class LastFmDataSourceImpl implements LastFmDataSource {
  final Dio _dio;
  static const String _baseUrl = 'https://ws.audioscrobbler.com/2.0/';

  LastFmDataSourceImpl()
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  String get _apiKey => dotenv.env['LASTFM_API_KEY'] ?? '';

  Map<String, dynamic> _baseParams(String method) {
    return {'method': method, 'api_key': _apiKey, 'format': 'json'};
  }

  @override
  Future<List<LastFmTrackModel>> getSimilarTracks(String artist, String track, {int limit = 10}) async {
    try {
      final response = await _dio.get('', queryParameters: {
        ..._baseParams('track.getsimilar'),
        'artist': artist,
        'track': track,
        'limit': limit,
      });
      final raw = response.data['similartracks']?['track'];
      final rawList = raw is List
          ? raw
          : (raw is Map ? [raw] : const <dynamic>[]);
      final tracks = rawList
          .map((t) => LastFmTrackModel.fromJson(t as Map<String, dynamic>))
          .where((t) => t.name.isNotEmpty)
          .toList();
      return tracks;
    } catch (e) {
      debugPrint('[LastFM] getSimilarTracks FAILED: $e');
      return [];
    }
  }

  @override
  Future<LastFmArtistModel?> getArtistInfo(String artist) async {
    try {
      final response = await _dio.get('', queryParameters: {
        ..._baseParams('artist.getinfo'),
        'artist': artist,
      });
      final artistData = response.data['artist'] as Map<String, dynamic>?;
      if (artistData == null) return null;
      return LastFmArtistModel.fromJson(artistData);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<LastFmTrackModel>> getArtistTopTracks(String artist, {int limit = 10}) async {
    try {
      final response = await _dio.get('', queryParameters: {
        ..._baseParams('artist.gettoptracks'),
        'artist': artist,
        'limit': limit,
      });
      final tracks = response.data['toptracks']?['track'] as List<dynamic>? ?? [];
      return tracks
          .map((t) => LastFmTrackModel.fromJson(t as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
