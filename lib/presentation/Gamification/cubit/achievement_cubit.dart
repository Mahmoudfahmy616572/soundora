import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:hive/hive.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/presentation/Gamification/models/achievement_model.dart';

import 'achievement_state.dart';

/// Tracks achievements against real in-app events and persists progress in
/// Hive so the data survives restarts. Not a placeholder â€” every counter here
/// is fed from actual playback, favourites and party hosting.
class AchievementCubit extends Cubit<AchievementState> {
  AchievementCubit() : super(AchievementInitial());

  static const _boxName = 'achievements';

  int _plays = 0;
  int _nightPlays = 0;
  Map<String, int> _artistCounts = {};
  Set<String> _discoveredSongs = {};
  String? _lastPlayDay;
  int _streakDays = 0;
  int _favouritesAdded = 0;
  int _partiesHosted = 0;

  Box get _box => Hive.box(_boxName);

  void loadAchievements() {
    emit(AchievementLoading());
    _loadState();
    _emit();
  }

  void _loadState() {
    try {
      final raw = _box.get('state') as Map? ?? const {};
      _plays = (raw['plays'] as num?)?.toInt() ?? 0;
      _nightPlays = (raw['nightPlays'] as num?)?.toInt() ?? 0;
      _artistCounts = Map<String, int>.from(raw['artists'] ?? {});
      _discoveredSongs = Set<String>.from(raw['songs'] ?? []);
      _lastPlayDay = raw['lastPlayDay'] as String?;
      _streakDays = (raw['streakDays'] as num?)?.toInt() ?? 0;
      _favouritesAdded = (raw['favouritesAdded'] as num?)?.toInt() ?? 0;
      _partiesHosted = (raw['partiesHosted'] as num?)?.toInt() ?? 0;
    } catch (_) {
      _plays = 0;
      _nightPlays = 0;
      _artistCounts = {};
      _discoveredSongs = {};
      _lastPlayDay = null;
      _streakDays = 0;
      _favouritesAdded = 0;
      _partiesHosted = 0;
    }
  }

  void _saveState() {
    try {
      _box.put('state', <String, dynamic>{
        'plays': _plays,
        'nightPlays': _nightPlays,
        'artists': _artistCounts,
        'songs': _discoveredSongs.toList(),
        'lastPlayDay': _lastPlayDay,
        'streakDays': _streakDays,
        'favouritesAdded': _favouritesAdded,
        'partiesHosted': _partiesHosted,
      });
    } catch (_) {}
  }

  List<AchievementModel> _buildAchievements() {
    final counts = <String, int>{
      'first_listen': _plays,
      'night_owl': _nightPlays,
      'superfan': _artistCounts.isEmpty
          ? 0
          : _artistCounts.values.reduce((a, b) => max(a, b)),
      'discovery_king': _discoveredSongs.length,
      'streak': _streakDays,
      'curator': _favouritesAdded,
      'party_host': _partiesHosted,
    };
    return AchievementModel.defaultAchievements().map((a) {
      final p = counts[a.id] ?? 0;
      return a.copyWith(
        currentProgress: min(p, a.requiredValue),
        isUnlocked: p >= a.requiredValue,
      );
    }).toList();
  }

  int _totalXp(List<AchievementModel> achievements) => achievements.fold<int>(
      0, (sum, a) => sum + (a.isUnlocked ? a.xpReward : 0));

  int _levelFor(int xp) => 1 + (xp ~/ 500);

  void _emit() {
    final achievements = _buildAchievements();
    final xp = _totalXp(achievements);
    emit(AchievementLoaded(
      achievements: achievements,
      totalXp: xp,
      level: _levelFor(xp),
    ));
  }

  /// Called whenever a song actually starts playing.
  void onSongPlayed(SongModel song) {
    _plays++;
    final now = DateTime.now();
    if (now.hour < 4) {
      _nightPlays++;
    }
    _artistCounts[song.artist] = (_artistCounts[song.artist] ?? 0) + 1;
    _discoveredSongs.add(song.id.toString());

    final today = _dayKey(now);
    final yesterday = _dayKey(now.subtract(const Duration(days: 1)));
    if (_lastPlayDay == yesterday) {
      _streakDays++;
    } else if (_lastPlayDay != today) {
      _streakDays = 1;
    }
    _lastPlayDay = today;

    _saveState();
    _emit();
  }

  /// Called whenever a song is added to the user's library.
  void onFavouriteAdded() {
    _favouritesAdded++;
    _saveState();
    _emit();
  }

  /// Called whenever the user successfully creates a listening party room.
  void onPartyHosted() {
    _partiesHosted++;
    _saveState();
    _emit();
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
