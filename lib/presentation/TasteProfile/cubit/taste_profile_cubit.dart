import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:soundora/data/models/taste_profile/taste_profile.dart';
import 'package:soundora/data/sources/listening_history/genre_detector.dart';
import 'package:soundora/data/sources/listening_history/listening_data_source.dart';

part 'taste_profile_state.dart';

class TasteProfileCubit extends Cubit<TasteProfileState> {
  final ListeningDataSource _listeningDataSource;
  final GenreDetector _genreDetector;
  static const String _boxName = 'taste_profile';

  TasteProfileCubit({
    ListeningDataSource? listeningDataSource,
    GenreDetector? genreDetector,
  })  : _listeningDataSource = listeningDataSource ?? ListeningDataSourceImpl(),
        _genreDetector = genreDetector ?? GenreDetector(),
        super(TasteProfileInitial());

  TasteProfile? get currentProfile {
    if (state is TasteProfileLoaded) {
      return (state as TasteProfileLoaded).profile;
    }
    return null;
  }

  Future<void> loadCachedProfile() async {
    try {
      final box = await Hive.openBox(_boxName);
      final raw = box.get('profile');
      if (raw != null) {
        final json = jsonDecode(raw.toString());
        final profile = TasteProfile(
          genreScores: Map<String, double>.from(json['genreScores'] ?? {}),
          topArtists: List<String>.from(json['topArtists'] ?? []),
          topGenres: List<String>.from(json['topGenres'] ?? []),
          primaryLanguage: json['primaryLanguage'] ?? 'unknown',
          moodScores: Map<String, double>.from(json['moodScores'] ?? {}),
          lastAnalyzed: DateTime.tryParse(json['lastAnalyzed'] ?? '') ?? DateTime.now(),
        );
        emit(TasteProfileLoaded(profile));
      }
    } catch (_) {}
  }

  Future<void> analyzeTaste() async {
    emit(TasteProfileAnalyzing());

    try {
      final playEvents = _listeningDataSource.getPlayEvents(limit: 200);
      final stats = _listeningDataSource.getAllListenStats();

      if (playEvents.isEmpty && stats.isEmpty) {
        emit(TasteProfileLoaded(TasteProfile(lastAnalyzed: DateTime.now())));
        return;
      }

      final artistPlayCount = <String, int>{};
      final artistWeight = <String, double>{};
      final languageCount = <String, int>{'arabic': 0, 'english': 0, 'other': 0};

      for (final event in playEvents) {
        final weight = event.completionRatio;
        artistPlayCount[event.artist] = (artistPlayCount[event.artist] ?? 0) + 1;
        artistWeight[event.artist] = (artistWeight[event.artist] ?? 0) + weight;

        final lang = _detectLanguage(event.title, event.artist);
        languageCount[lang] = (languageCount[lang] ?? 0) + 1;
      }

      for (final entry in stats.entries) {
        final s = entry.value;
        artistPlayCount[s.artist] = (artistPlayCount[s.artist] ?? 0) + s.playCount;
        artistWeight[s.artist] = (artistWeight[s.artist] ?? 0) + s.averageCompletion * s.playCount;
      }

      final sortedArtists = artistWeight.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topArtists = sortedArtists.take(15).map((e) => e.key).toList();

      final genreScores = <String, double>{};
      for (final artist in topArtists) {
        final genres = await _genreDetector.detectGenresForArtist(artist);
        final weight = (artistWeight[artist] ?? 0) / (topArtists.length);
        for (final genre in genres) {
          genreScores[genre] = (genreScores[genre] ?? 0) + weight;
        }
      }

      final sortedGenres = genreScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topGenres = sortedGenres.take(5).map((e) => e.key).toList();

      final primaryLang = languageCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final primaryLanguage = primaryLang.isNotEmpty ? primaryLang.first.key : 'unknown';

      final moodScores = _analyzeMood(playEvents);

      final profile = TasteProfile(
        genreScores: genreScores,
        topArtists: topArtists,
        topGenres: topGenres,
        primaryLanguage: primaryLanguage,
        moodScores: moodScores,
        lastAnalyzed: DateTime.now(),
      );

      await _cacheProfile(profile);
      emit(TasteProfileLoaded(profile));
    } catch (e) {
      emit(TasteProfileError('Failed to analyze taste: $e'));
    }
  }

  Map<String, double> _analyzeMood(List<PlayEvent> events) {
    final moods = <String, double>{
      'energetic': 0,
      'chill': 0,
      'happy': 0,
      'sad': 0,
    };

    for (final event in events) {
      final hour = event.timestamp.hour;
      final ratio = event.completionRatio;

      if (hour >= 6 && hour < 12) {
        moods['energetic'] = (moods['energetic'] ?? 0) + ratio;
      } else if (hour >= 12 && hour < 18) {
        moods['happy'] = (moods['happy'] ?? 0) + ratio;
      } else if (hour >= 18 && hour < 22) {
        moods['chill'] = (moods['chill'] ?? 0) + ratio;
      } else {
        moods['sad'] = (moods['sad'] ?? 0) + ratio;
      }
    }

    final total = moods.values.fold(0.0, (sum, v) => sum + v);
    if (total > 0) {
      for (final key in moods.keys) {
        moods[key] = (moods[key] ?? 0) / total;
      }
    }

    return moods;
  }

  String _detectLanguage(String title, String artist) {
    if (_genreDetector.isArabicArtist(artist)) return 'arabic';
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    if (arabicRegex.hasMatch(title) || arabicRegex.hasMatch(artist)) return 'arabic';
    return 'english';
  }

  Future<void> _cacheProfile(TasteProfile profile) async {
    try {
      final box = await Hive.openBox(_boxName);
      final json = jsonEncode({
        'genreScores': profile.genreScores,
        'topArtists': profile.topArtists,
        'topGenres': profile.topGenres,
        'primaryLanguage': profile.primaryLanguage,
        'moodScores': profile.moodScores,
        'lastAnalyzed': profile.lastAnalyzed.toIso8601String(),
      });
      await box.put('profile', json);
    } catch (_) {}
  }
}
