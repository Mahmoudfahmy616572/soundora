import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:hive/hive.dart';
import 'package:soundora/presentation/LyricsMemory/models/lyrics_memory_model.dart';

import 'lyrics_memory_state.dart';

class LyricsMemoryCubit extends Cubit<LyricsMemoryState> {
  final Box _memoryBox;

  LyricsMemoryCubit({Box? memoryBox})
      : _memoryBox = memoryBox ?? Hive.box('lyrics_memory'),
        super(LyricsMemoryInitial());

  void loadMemory() {
    emit(LyricsMemoryLoading());
    final entries = _loadEntries();
    emit(LyricsMemoryLoaded(
      allEntries: entries,
      forgottenSongs: _getForgotten(entries),
      recentSongs: _getRecent(entries),
      onThisDaySongs: _getOnThisDay(entries),
      stats: _computeStats(entries),
    ));
  }

  void recordPlay(
    String songId,
    String title,
    String artist,
    String imageUrl,
  ) {
    final entries = _loadEntries();
    final existing = entries.where((e) => e.songId == songId).toList();

    if (existing.isNotEmpty) {
      final entry = existing.first;
      final updated = entry.copyWith(
        lastHeard: DateTime.now(),
        timesListened: entry.timesListened + 1,
      );
      entries.removeWhere((e) => e.songId == songId);
      entries.add(updated);
    } else {
      entries.add(LyricsMemoryEntry(
        songId: songId,
        title: title,
        artist: artist,
        imageUrl: imageUrl,
        firstHeard: DateTime.now(),
        lastHeard: DateTime.now(),
      ));
    }

    _saveEntries(entries);
    emit(LyricsMemoryLoaded(
      allEntries: entries,
      forgottenSongs: _getForgotten(entries),
      recentSongs: _getRecent(entries),
      onThisDaySongs: _getOnThisDay(entries),
      stats: _computeStats(entries),
    ));
  }

  void markLineAsFavorite(String songId, String line) {
    final entries = _loadEntries();
    final entryIndex = entries.indexWhere((e) => e.songId == songId);
    if (entryIndex == -1) return;

    final entry = entries[entryIndex];
    if (entry.favoriteLines.contains(line)) return;

    entries[entryIndex] = entry.copyWith(
      favoriteLines: [...entry.favoriteLines, line],
    );

    _saveEntries(entries);
  }

  List<LyricsMemoryEntry> _getForgotten(List<LyricsMemoryEntry> entries) {
    final forgotten = entries.where((e) => e.isForgotten).toList();
    forgotten.sort((a, b) => a.lastHeard.compareTo(b.lastHeard));
    return forgotten.take(20).toList();
  }

  List<LyricsMemoryEntry> _getRecent(List<LyricsMemoryEntry> entries) {
    final recent = entries.where((e) => e.isRecent).toList();
    recent.sort((a, b) => b.lastHeard.compareTo(a.lastHeard));
    return recent.take(20).toList();
  }

  List<LyricsMemoryEntry> _getOnThisDay(List<LyricsMemoryEntry> entries) {
    final now = DateTime.now();
    return entries.where((e) {
      final diff = now.difference(e.lastHeard).inDays;
      return diff >= 364 && diff <= 366 ||
          diff >= 729 && diff <= 731 ||
          diff >= 1094 && diff <= 1096;
    }).toList();
  }

  LyricsMemoryStats _computeStats(List<LyricsMemoryEntry> entries) {
    if (entries.isEmpty) {
      return const LyricsMemoryStats(
        totalUniqueSongs: 0,
        totalPlays: 0,
        daysUsingApp: 0,
        topArtist: '',
      );
    }

    final totalPlays =
        entries.fold<int>(0, (sum, e) => sum + e.timesListened);

    final artistCounts = <String, int>{};
    for (final e in entries) {
      artistCounts[e.artist] = (artistCounts[e.artist] ?? 0) + 1;
    }
    final topArtist = artistCounts.isNotEmpty
        ? artistCounts.entries
            .reduce((a, b) => a.value >= b.value ? a : b)
            .key
        : '';

    final oldestEntry = entries.reduce(
        (a, b) => a.firstHeard.isBefore(b.firstHeard) ? a : b);
    final daysUsing = DateTime.now().difference(oldestEntry.firstHeard).inDays;

    return LyricsMemoryStats(
      totalUniqueSongs: entries.length,
      totalPlays: totalPlays,
      daysUsingApp: daysUsing,
      topArtist: topArtist,
    );
  }

  List<LyricsMemoryEntry> _loadEntries() {
    final raw = _memoryBox.get('entries');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw as String) as List;
      return list
          .map((e) => LyricsMemoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _saveEntries(List<LyricsMemoryEntry> entries) {
    final json = jsonEncode(entries.map((e) => e.toJson()).toList());
    _memoryBox.put('entries', json);
  }
}
