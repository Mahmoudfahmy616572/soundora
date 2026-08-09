import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/data/models/taste_profile/taste_profile.dart';
import 'package:soundora/data/sources/deezer/deezer_data_source.dart';
import 'package:soundora/data/sources/lastfm/lastfm_data_source.dart';
import 'package:soundora/data/sources/listening_history/listening_data_source.dart';
import 'package:soundora/presentation/TasteProfile/cubit/taste_profile_cubit.dart';
import 'package:soundora/serviece_locator.dart';

part 'smart_home_state.dart';

class SmartHomeCubit extends Cubit<SmartHomeState> {
  final TasteProfileCubit _tasteProfileCubit;
  final ListeningDataSource _listeningDataSource;

  static const double _recencyHalfLife = 30 * 24 * 60 * 60 * 1000.0;

  SmartHomeCubit({
    required TasteProfileCubit tasteProfileCubit,
    ListeningDataSource? listeningDataSource,
  })  : _tasteProfileCubit = tasteProfileCubit,
        _listeningDataSource = listeningDataSource ?? ListeningDataSourceImpl(),
        super(SmartHomeInitial());

  Future<void> loadPersonalizedContent({
    required List<SongModel> allNewSongs,
    required List<SongModel> allRecentlyPlayed,
  }) async {
    emit(SmartHomeLoading());

    try {
      final profile = _tasteProfileCubit.currentProfile;
      final statsMap = _listeningDataSource.getAllListenStats();
      final stats = statsMap.values.toList();
      final hasTaste = profile != null &&
          (profile.topArtists.isNotEmpty || profile.topGenres.isNotEmpty);

      final topPlayed = _buildTopPlayed(stats, allRecentlyPlayed, allNewSongs);

      var similarSongs = <SongModel>[];
      var similarBasedOn = '';
      if (topPlayed.isNotEmpty) {
        final seed = _pickSimilarSeed(topPlayed, statsMap);
        similarSongs = await _fetchSimilarTo(seed, profile);
        if (similarSongs.isNotEmpty) {
          similarBasedOn = '${seed.title} • ${seed.artist}';
          final playedIds = {for (final s in topPlayed) s.id};
          similarSongs =
              similarSongs.where((s) => !playedIds.contains(s.id)).toList();
        }
      }

      final forYou = hasTaste
          ? _rankForYou(allNewSongs, profile, statsMap)
          : _rankByPopularity(allNewSongs, statsMap);

      emit(SmartHomeContent(
        forYou: forYou.take(6).toList(),
        topPlayed: topPlayed.take(8).toList(),
        similarSongs: similarSongs.take(6).toList(),
        similarBasedOn: similarBasedOn,
        newSongs: allNewSongs,
        recentlyPlayed: allRecentlyPlayed,
        topGenres: hasTaste ? profile.topGenres.take(3).toList() : const [],
        topArtists: hasTaste ? profile.topArtists.take(5).toList() : const [],
      ));
    } catch (e, st) {
      debugPrint('[SmartHome] loadPersonalizedContent ERROR: $e\n$st');
      emit(SmartHomeError('Failed to load personalized content'));
    }
  }

  // ---------------------------------------------------------------
  // 1) "اللي بتحب تسمعه": affinity = frequency + completion + recency
  // ---------------------------------------------------------------
  List<SongModel> _buildTopPlayed(
    List<ListenStats> stats,
    List<SongModel> recentlyPlayed,
    List<SongModel> pool,
  ) {
    if (stats.isEmpty) return const [];

    final poolById = {for (final s in pool) s.id: s};
    final recentById = {for (final s in recentlyPlayed) s.id: s};

    final eligible = stats.where((s) {
      if (s.isSkippedOften) return false;
      return s.isFavourite || s.playCount >= 2;
    }).toList()
      ..sort((a, b) => _listenScore(b).compareTo(_listenScore(a)));

    final result = <SongModel>[];
    final seen = <String>{};
    for (final stat in eligible) {
      final full = recentById[stat.songId] ??
          poolById[stat.songId] ??
          _buildFallback(stat);
      if (full == null) continue;
      if (seen.contains(full.id)) continue;
      seen.add(full.id);
      result.add(full);
      if (result.length >= 8) break;
    }
    return result;
  }

  double _listenScore(ListenStats s) {
    final frequency = math.log(s.playCount + 1) / math.log(3); // 0..1
    final completion = s.averageCompletion.clamp(0, 1);
    final recency = math.pow(0.5, s.recencyMs / _recencyHalfLife).toDouble();
    return 0.45 * frequency + 0.3 * completion + 0.25 * recency;
  }

  SongModel? _buildFallback(ListenStats stat) {
    if (stat.title.isEmpty || stat.artist.isEmpty) return null;
    return SongModel(
      id: stat.songId,
      title: stat.title,
      artist: stat.artist,
      urlSongsbase: '',
      imageUrl: '',
      duration: '0:00',
      releaseDate: DateTime(2000),
      lyrics: '',
    );
  }

  // Most recently played favourite => reflects CURRENT taste.
  // Uses the full SongModel so artist/title are reliable for LastFM.
  SongModel _pickSimilarSeed(
    List<SongModel> topPlayed,
    Map<String, ListenStats> statsMap,
  ) {
    var best = topPlayed.first;
    var bestTime = -1;
    for (final song in topPlayed) {
      final stat = statsMap[song.id];
      if (stat != null && stat.lastPlayed > bestTime) {
        bestTime = stat.lastPlayed;
        best = song;
      }
    }
    return best;
  }

  // ---------------------------------------------------------------
  // 2) "شبه اللي بتحب": Deezer related-artist discovery (id-based,
  //    Arabic-safe, real previews) with LastFM fallback for English.
  // ---------------------------------------------------------------
  Future<List<SongModel>> _fetchSimilarTo(
    SongModel seed,
    TasteProfile? profile,
  ) async {
    try {
      final deezer = getIt<DeezerDataSource>();

      final artistRef = await _resolveArtistRef(deezer, seed);
      if (artistRef != null) {
        final related = await deezer.getRelatedArtists(artistRef.id, limit: 4);
        final artistIds = [
          artistRef.id,
          ...related.map((r) => r.id),
        ].take(3).toSet();

        final candidates = <SongModel>[];
        for (final artistId in artistIds) {
          candidates.addAll(await deezer.getArtistTopTracks(artistId, limit: 10));
        }

        final songs = candidates
            .where((s) => s.title.isNotEmpty && s.title != seed.title)
            .toList();
        if (songs.isNotEmpty) {
          final ranked = profile != null
              ? _rankForYou(songs, profile, const {})
              : songs;
          return _diversify(ranked, maxPerArtist: 2).take(8).toList();
        }
      }
    } catch (e) {
      debugPrint('[SmartHome] Deezer similar failed, trying LastFM: $e');
    }

    return _fetchSimilarLastFm(seed, profile);
  }

  Future<DeezerArtistRef?> _resolveArtistRef(
    DeezerDataSource deezer,
    SongModel seed,
  ) async {
    final seedId = int.tryParse(seed.id);
    if (seedId != null && seedId > 0) {
      final ref = await deezer.getTrackArtist(seedId);
      if (ref != null) return ref;
    }
    if (seed.artist.isNotEmpty) {
      final results = await deezer.searchTracks(seed.artist, limit: 5);
      for (final song in results) {
        final sid = int.tryParse(song.id);
        if (sid == null || sid <= 0) continue;
        final ref = await deezer.getTrackArtist(sid);
        if (ref != null) return ref;
      }
    }
    return null;
  }

  Future<List<SongModel>> _fetchSimilarLastFm(
    SongModel seed,
    TasteProfile? profile,
  ) async {
    try {
      final lastFm = getIt<LastFmDataSource>();
      final tracks = await lastFm.getSimilarTracks(
        seed.artist,
        seed.title,
        limit: 15,
      );

      final songs = tracks
          .map((t) => SongModel(
                id: t.name.hashCode.toString(),
                title: t.name,
                artist: t.artist,
                urlSongsbase: '',
                imageUrl: t.imageUrl ?? '',
                duration: '0:00',
                releaseDate: DateTime(2000),
                lyrics: '',
              ))
          .where((s) => s.title.isNotEmpty)
          .toList();

      if (songs.isEmpty) return const [];

      final ranked = profile != null
          ? _rankForYou(songs, profile, const {})
          : songs.take(8).toList();
      return _diversify(ranked, maxPerArtist: 2);
    } catch (_) {
      return const [];
    }
  }

  // ---------------------------------------------------------------
  // 3) "من زوقك": hybrid collaborative + content affinity
  // ---------------------------------------------------------------
  List<SongModel> _rankForYou(
    List<SongModel> songs,
    TasteProfile profile,
    Map<String, ListenStats> statsMap,
  ) {
    final now = DateTime.now().millisecondsSinceEpoch;

    final scored = songs.map((song) {
      double score = 0;

      // Content affinity: artist rank in profile.
      final artistIdx = profile.topArtists.indexOf(song.artist);
      if (artistIdx >= 0) {
        score += (10 - artistIdx) * 1.2;
      }

      // Language match.
      if (_detectLanguage(song.title, song.artist) == profile.primaryLanguage) {
        score += 3;
      }

      // Weak genre text signal (title/artist rarely contains genre).
      for (final genre in profile.topGenres) {
        if (song.title.toLowerCase().contains(genre) ||
            song.artist.toLowerCase().contains(genre)) {
          score += 1.5;
        }
      }

      // Collaborative signal: user's own listening stats for this song.
      final stat = statsMap[song.id];
      if (stat != null && !stat.isSkippedOften) {
        final recency = math.pow(0.5, (now - stat.lastPlayed) / _recencyHalfLife).toDouble();
        score += 2.5 * math.log(stat.playCount + 1) + 2 * stat.averageCompletion + 2 * recency;
      } else if (stat != null && stat.isSkippedOften) {
        score -= 4;
      }

      return MapEntry(song, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return _diversify(scored.map((e) => e.key).toList(), maxPerArtist: 2);
  }

  // No taste signal yet: rank the real pool by the user's OWN stats,
  // falling back to the source order (charts).
  List<SongModel> _rankByPopularity(
    List<SongModel> songs,
    Map<String, ListenStats> statsMap,
  ) {
    if (songs.isEmpty) return const [];

    final ranked = List<SongModel>.from(songs);
    ranked.sort((a, b) {
      final sa = statsMap[a.id];
      final sb = statsMap[b.id];
      if (sa != null && sb != null) {
        final c = sb.playCount.compareTo(sa.playCount);
        if (c != 0) return c;
        return sb.averageCompletion.compareTo(sa.averageCompletion);
      }
      if (sa != null) return -1;
      if (sb != null) return 1;
      return 0;
    });
    return ranked.take(6).toList();
  }

  // Prevent one artist flooding a row.
  List<SongModel> _diversify(List<SongModel> songs, {int maxPerArtist = 2}) {
    final result = <SongModel>[];
    final perArtist = <String, int>{};
    for (final song in songs) {
      final count = perArtist[song.artist] ?? 0;
      if (count >= maxPerArtist) continue;
      perArtist[song.artist] = count + 1;
      result.add(song);
    }
    return result;
  }

  String _detectLanguage(String title, String artist) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    if (arabicRegex.hasMatch(title) || arabicRegex.hasMatch(artist)) return 'arabic';
    return 'english';
  }
}
