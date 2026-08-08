import 'package:soundora/data/sources/lastfm/lastfm_data_source.dart';
import 'package:soundora/serviece_locator.dart';

class GenreDetector {
  final Map<String, List<String>> _cache = {};

  Future<List<String>> detectGenresForArtist(String artist) async {
    if (_cache.containsKey(artist)) return _cache[artist]!;

    try {
      final lastFm = getIt<LastFmDataSource>();
      final info = await lastFm.getArtistInfo(artist);
      if (info != null && info.tags.isNotEmpty) {
        _cache[artist] = info.tags;
        return info.tags;
      }
    } catch (_) {}

    return [];
  }

  Future<Map<String, int>> detectGenreScores(List<String> artists) async {
    final genreCount = <String, int>{};

    for (final artist in artists) {
      final genres = await detectGenresForArtist(artist);
      for (final genre in genres) {
        final normalized = _normalizeGenre(genre);
        genreCount[normalized] = (genreCount[normalized] ?? 0) + 1;
      }
    }

    return genreCount;
  }

  String _normalizeGenre(String raw) {
    final lower = raw.toLowerCase().trim();
    const mapping = {
      'arabic pop': 'arabic pop',
      'arabic': 'arabic',
      'egyptian': 'arabic',
      'egyptian pop': 'arabic pop',
      'middle eastern': 'arabic',
      'pop': 'pop',
      'pop rock': 'pop rock',
      'hip hop': 'hip hop',
      'rap': 'hip hop',
      'r&b': 'r&b',
      'rnb': 'r&b',
      'rock': 'rock',
      'alternative rock': 'rock',
      'indie rock': 'rock',
      'electronic': 'electronic',
      'edm': 'electronic',
      'dance': 'electronic',
      'house': 'electronic',
      'jazz': 'jazz',
      'blues': 'blues',
      'classical': 'classical',
      'country': 'country',
      'reggae': 'reggae',
      'latin': 'latin',
      'reggaeton': 'latin',
      'k-pop': 'k-pop',
      'bollywood': 'bollywood',
      'indian': 'bollywood',
    };

    for (final entry in mapping.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return lower;
  }

  bool isArabicArtist(String artist) {
    final arabicKeywords = [
      'amr diab', 'tamer hosny', 'hamada helal', 'mohamed ramadan',
      'wael kfoury', 'fadel shaker', 'nancy ajram', 'fairuz',
      'abdel halim', 'omar khairat', 'cairokee', 'the5thband',
      'amr diab', 'hakim', 'maher zain', 'hamza namira',
      'ruby', 'hanashi', 'mohamed mounir', 'ali deek',
      'bolbol', 'marwan moussa', 'wegz', 'ashmawy', 'zughrat',
    ];
    return arabicKeywords.any((k) => artist.toLowerCase().contains(k));
  }
}
