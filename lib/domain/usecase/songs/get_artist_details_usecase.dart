import 'package:soundora/data/sources/audiodb/audiodb_data_source.dart';
import 'package:soundora/data/sources/lastfm/lastfm_data_source.dart';
import 'package:soundora/data/sources/models/combined_artist_model.dart';
import 'package:soundora/data/sources/wolfxspotify/wolfxspotify_data_source.dart';
import 'package:soundora/domain/usecase/usecase.dart';
import 'package:soundora/serviece_locator.dart';

class ArtistDetailsParam {
  final String artistName;
  final String? artistId;

  const ArtistDetailsParam({required this.artistName, this.artistId});
}

class GetArtistDetailsUsecase
    implements Usecase<CombinedArtistModel?, ArtistDetailsParam> {
  @override
  Future<CombinedArtistModel?> call({ArtistDetailsParam? param}) async {
    if (param == null) return null;

    final wolfx = getIt<WolfXSpotifyDataSource>();
    final audioDb = getIt<AudioDbDataSource>();
    final lastFm = getIt<LastFmDataSource>();

    try {
      final futures = await Future.wait([
        param.artistId != null
            ? wolfx.getArtist(param.artistId!)
            : Future.value(null),
        param.artistId != null
            ? wolfx.getArtistTopTracks(param.artistId!)
            : Future.value([]),
        audioDb.searchArtist(param.artistName),
        lastFm.getArtistInfo(param.artistName),
        lastFm.getArtistTopTracks(param.artistName),
      ]);

      final wolfxArtist = futures[0] as dynamic;
      final wolfxTopTracks = futures[1] as List<dynamic>;
      final audioDbArtist = futures[2] as dynamic;
      final lastFmArtist = futures[3] as dynamic;
      final lastFmTopTracks = futures[4] as List<dynamic>;

      final genres = <String>[];
      if (wolfxArtist != null) {
        try {
          for (final g in (wolfxArtist.genres as List<dynamic>? ?? [])) {
            genres.add(g.toString());
          }
        } catch (_) {}
      }

      final topTrackNames = <String>[];
      if (wolfxTopTracks.isNotEmpty) {
        for (final t in wolfxTopTracks) {
          try {
            topTrackNames.add(t.name.toString());
          } catch (_) {}
        }
      } else if (lastFmTopTracks.isNotEmpty) {
        for (final t in lastFmTopTracks) {
          try {
            topTrackNames.add(t.name.toString());
          } catch (_) {}
        }
      }

      final similarArtistNames = <String>[];

      return CombinedArtistModel(
        id: _safeString(() => wolfxArtist?.id) ??
            _safeString(() => audioDbArtist?.id) ??
            '',
        name: _safeString(() => wolfxArtist?.name) ??
            _safeString(() => audioDbArtist?.name) ??
            _safeString(() => lastFmArtist?.name) ??
            param.artistName,
        imageUrl: _safeString(() => wolfxArtist?.imageUrl) ??
            _safeString(() => audioDbArtist?.imageUrl) ??
            _safeString(() => lastFmArtist?.imageUrl),
        bannerUrl: _safeString(() => audioDbArtist?.banner),
        biography: _safeString(() => audioDbArtist?.biography) ??
            _safeString(() => lastFmArtist?.biography),
        genres: genres,
        country: _safeString(() => audioDbArtist?.country),
        followers: _safeInt(() => wolfxArtist?.followers),
        listeners: _safeInt(() => lastFmArtist?.listeners),
        popularity: _safeInt(() => wolfxArtist?.popularity),
        topTrackNames: topTrackNames,
        similarArtistNames: similarArtistNames,
      );
    } catch (_) {
      return null;
    }
  }

  String? _safeString(dynamic Function() getter) {
    try {
      final result = getter();
      return result?.toString();
    } catch (_) {
      return null;
    }
  }

  int? _safeInt(dynamic Function() getter) {
    try {
      final result = getter();
      if (result is int) return result;
      if (result is num) return result.toInt();
      return null;
    } catch (_) {
      return null;
    }
  }
}
