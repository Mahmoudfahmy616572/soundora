import 'dart:convert';

import 'package:hive/hive.dart';

abstract class ListeningDataSource {
  Future<void> recordSearch(String query);
  List<String> getSearchHistory({int limit = 20});
  Future<void> clearSearchHistory();

  Future<void> recordPlayEvent(PlayEvent event);
  List<PlayEvent> getPlayEvents({int limit = 200});

  Future<void> recordSkip(String songId, String title, String artist, Duration listenedDuration);
  List<SkipRecord> getSkipRecords({int limit = 200});

  Future<void> recordListenDuration(String songId, String title, String artist, Duration duration, Duration totalDuration);
  Map<String, ListenStats> getAllListenStats();

  Future<void> clearAll();
}

class PlayEvent {
  final String songId;
  final String title;
  final String artist;
  final DateTime timestamp;
  final Duration listenedDuration;
  final Duration totalDuration;
  final bool wasSkipped;

  PlayEvent({
    required this.songId,
    required this.title,
    required this.artist,
    required this.timestamp,
    required this.listenedDuration,
    required this.totalDuration,
    required this.wasSkipped,
  });

  double get completionRatio {
    if (totalDuration.inSeconds == 0) return 0;
    return listenedDuration.inSeconds / totalDuration.inSeconds;
  }

  Map<String, dynamic> toJson() => {
        'songId': songId,
        'title': title,
        'artist': artist,
        'timestamp': timestamp.toIso8601String(),
        'listenedDuration': listenedDuration.inMilliseconds,
        'totalDuration': totalDuration.inMilliseconds,
        'wasSkipped': wasSkipped,
      };

  factory PlayEvent.fromJson(Map<String, dynamic> json) => PlayEvent(
        songId: json['songId'] ?? '',
        title: json['title'] ?? '',
        artist: json['artist'] ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
        listenedDuration: Duration(milliseconds: json['listenedDuration'] ?? 0),
        totalDuration: Duration(milliseconds: json['totalDuration'] ?? 0),
        wasSkipped: json['wasSkipped'] ?? false,
      );
}

class SkipRecord {
  final String songId;
  final String title;
  final String artist;
  final DateTime timestamp;
  final Duration listenedBeforeSkip;

  SkipRecord({
    required this.songId,
    required this.title,
    required this.artist,
    required this.timestamp,
    required this.listenedBeforeSkip,
  });

  Map<String, dynamic> toJson() => {
        'songId': songId,
        'title': title,
        'artist': artist,
        'timestamp': timestamp.toIso8601String(),
        'listenedBeforeSkip': listenedBeforeSkip.inMilliseconds,
      };

  factory SkipRecord.fromJson(Map<String, dynamic> json) => SkipRecord(
        songId: json['songId'] ?? '',
        title: json['title'] ?? '',
        artist: json['artist'] ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
        listenedBeforeSkip: Duration(milliseconds: json['listenedBeforeSkip'] ?? 0),
      );
}

class ListenStats {
  final String songId;
  final String title;
  final String artist;
  int playCount;
  Duration totalListened;
  Duration totalDuration;
  int skipCount;
  int lastPlayed;

  ListenStats({
    required this.songId,
    required this.title,
    required this.artist,
    this.playCount = 0,
    this.totalListened = Duration.zero,
    this.totalDuration = Duration.zero,
    this.skipCount = 0,
    this.lastPlayed = 0,
  });

  double get averageCompletion {
    if (playCount == 0 || totalDuration.inSeconds == 0) return 0;
    return totalListened.inSeconds / (playCount * totalDuration.inSeconds);
  }

  bool get isFavourite => playCount >= 3 && averageCompletion > 0.6;
  bool get isSkippedOften => skipCount >= 2 && playCount > 0 && skipCount / playCount > 0.5;

  int get recencyMs => DateTime.now().millisecondsSinceEpoch - lastPlayed;

  Map<String, dynamic> toJson() => {
        'songId': songId,
        'title': title,
        'artist': artist,
        'playCount': playCount,
        'totalListened': totalListened.inMilliseconds,
        'totalDuration': totalDuration.inMilliseconds,
        'skipCount': skipCount,
        'lastPlayed': lastPlayed,
      };

  factory ListenStats.fromJson(Map<String, dynamic> json) => ListenStats(
        songId: json['songId'] ?? '',
        title: json['title'] ?? '',
        artist: json['artist'] ?? '',
        playCount: json['playCount'] ?? 0,
        totalListened: Duration(milliseconds: json['totalListened'] ?? 0),
        totalDuration: Duration(milliseconds: json['totalDuration'] ?? 0),
        skipCount: json['skipCount'] ?? 0,
        lastPlayed: json['lastPlayed'] ?? 0,
      );
}

class ListeningDataSourceImpl implements ListeningDataSource {
  static const String _searchBox = 'search_history';
  static const String _playEventsBox = 'play_events';
  static const String _skipRecordsBox = 'skip_records';
  static const String _listenStatsBox = 'listen_stats';

  static const int _maxSearchHistory = 30;
  static const int _maxPlayEvents = 200;
  static const int _maxSkipRecords = 200;
  static const int _maxListenStats = 300;

  // Legacy single-list keys, replaced by one key per record.
  static const String _legacyEventsKey = 'events';
  static const String _legacySkipsKey = 'skips';
  static const String _legacyStatsKey = 'stats';

  static bool _migrated = false;
  int _seq = 0;

  Box get _searchBoxRef => Hive.box(_searchBox);
  Box get _playEventsBoxRef => Hive.box(_playEventsBox);
  Box get _skipRecordsBoxRef => Hive.box(_skipRecordsBox);
  Box get _listenStatsBoxRef => Hive.box(_listenStatsBox);

  ListeningDataSourceImpl() {
    _migrate();
  }

  String _uniqueKey(String prefix) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch}_${_seq++}';

  Future<void> _migrate() async {
    if (_migrated) return;
    _migrated = true;
    try {
      await _migrateListBox(
          _playEventsBoxRef, _legacyEventsKey, 'ev:', _maxPlayEvents);
      await _migrateListBox(
          _skipRecordsBoxRef, _legacySkipsKey, 'sk:', _maxSkipRecords);
      await _migrateStatsBox();
    } catch (_) {}
  }

  Future<void> _migrateListBox(
      Box box, String legacyKey, String prefix, int max) async {
    final legacy = box.get(legacyKey);
    if (legacy is List) {
      for (final e in legacy.take(max)) {
        await box.put(_uniqueKey(prefix), e.toString());
      }
      await box.delete(legacyKey);
    }
  }

  Future<void> _migrateStatsBox() async {
    final legacy = _listenStatsBoxRef.get(_legacyStatsKey);
    if (legacy is List) {
      for (final e in legacy) {
        try {
          final s = ListenStats.fromJson(jsonDecode(e.toString()));
          await _listenStatsBoxRef.put(s.songId, e.toString());
        } catch (_) {}
      }
      await _listenStatsBoxRef.delete(_legacyStatsKey);
    }
  }

  List<dynamic> _legacyList(Box box, String legacyKey) {
    final raw = box.get(legacyKey);
    return raw is List ? raw : const [];
  }

  @override
  Future<void> recordSearch(String query) async {
    if (query.trim().isEmpty) return;
    final searches = _searchBoxRef.get('queries', defaultValue: <String>[]) as List;
    searches.remove(query);
    searches.insert(0, query);
    if (searches.length > _maxSearchHistory) {
      searches.removeRange(_maxSearchHistory, searches.length);
    }
    await _searchBoxRef.put('queries', searches);
  }

  @override
  List<String> getSearchHistory({int limit = 20}) {
    final searches = _searchBoxRef.get('queries', defaultValue: <String>[]) as List;
    return searches.take(limit).map((e) => e.toString()).toList();
  }

  @override
  Future<void> clearSearchHistory() async {
    await _searchBoxRef.put('queries', <String>[]);
  }

  @override
  Future<void> recordPlayEvent(PlayEvent event) async {
    final box = _playEventsBoxRef;
    await box.put(_uniqueKey('ev:'), jsonEncode(event.toJson()));
    if (box.length > _maxPlayEvents) {
      final toDelete = box.keys.take(box.length - _maxPlayEvents).toList();
      await box.deleteAll(toDelete);
    }
    await _updateListenStats(event);
  }

  @override
  List<PlayEvent> getPlayEvents({int limit = 200}) {
    final box = _playEventsBoxRef;
    final events = <(int, PlayEvent)>[];
    box.toMap().forEach((k, v) {
      if (k == _legacyEventsKey) return;
      try {
        final e = PlayEvent.fromJson(jsonDecode(v.toString()));
        events.add((e.timestamp.microsecondsSinceEpoch, e));
      } catch (_) {}
    });
    // Legacy list (newest first) while migration is still running.
    for (final raw in _legacyList(box, _legacyEventsKey)) {
      try {
        final e = PlayEvent.fromJson(jsonDecode(raw.toString()));
        events.add((e.timestamp.microsecondsSinceEpoch, e));
      } catch (_) {}
    }
    events.sort((a, b) => b.$1.compareTo(a.$1));
    return events.take(limit).map((e) => e.$2).toList();
  }

  @override
  Future<void> recordSkip(String songId, String title, String artist, Duration listenedDuration) async {
    final box = _skipRecordsBoxRef;
    final record = SkipRecord(
      songId: songId,
      title: title,
      artist: artist,
      timestamp: DateTime.now(),
      listenedBeforeSkip: listenedDuration,
    );
    await box.put(_uniqueKey('sk:'), jsonEncode(record.toJson()));
    if (box.length > _maxSkipRecords) {
      final toDelete = box.keys.take(box.length - _maxSkipRecords).toList();
      await box.deleteAll(toDelete);
    }

    final stats = _getStatsForSong(songId, title, artist);
    stats.skipCount++;
    stats.lastPlayed = DateTime.now().millisecondsSinceEpoch;
    await _saveStats(stats);
  }

  @override
  List<SkipRecord> getSkipRecords({int limit = 200}) {
    final box = _skipRecordsBoxRef;
    final skips = <(int, SkipRecord)>[];
    box.toMap().forEach((k, v) {
      if (k == _legacySkipsKey) return;
      try {
        final s = SkipRecord.fromJson(jsonDecode(v.toString()));
        skips.add((s.timestamp.microsecondsSinceEpoch, s));
      } catch (_) {}
    });
    // Legacy list (newest first) while migration is still running.
    for (final raw in _legacyList(box, _legacySkipsKey)) {
      try {
        final s = SkipRecord.fromJson(jsonDecode(raw.toString()));
        skips.add((s.timestamp.microsecondsSinceEpoch, s));
      } catch (_) {}
    }
    skips.sort((a, b) => b.$1.compareTo(a.$1));
    return skips.take(limit).map((e) => e.$2).toList();
  }

  @override
  Future<void> recordListenDuration(
      String songId, String title, String artist, Duration duration, Duration totalDuration) async {
    final stats = _getStatsForSong(songId, title, artist);
    stats.totalListened += duration;
    stats.totalDuration = totalDuration;
    await _saveStats(stats);
  }

  @override
  Map<String, ListenStats> getAllListenStats() {
    final box = _listenStatsBoxRef;
    final map = <String, ListenStats>{};
    for (final raw in _legacyList(box, _legacyStatsKey)) {
      try {
        final stats = ListenStats.fromJson(jsonDecode(raw.toString()));
        map[stats.songId] = stats;
      } catch (_) {}
    }
    box.toMap().forEach((k, v) {
      if (k == _legacyStatsKey) return;
      try {
        final stats = ListenStats.fromJson(jsonDecode(v.toString()));
        map[stats.songId] = stats;
      } catch (_) {}
    });
    return map;
  }

  @override
  Future<void> clearAll() async {
    await _searchBoxRef.clear();
    await _playEventsBoxRef.clear();
    await _skipRecordsBoxRef.clear();
    await _listenStatsBoxRef.clear();
  }

  ListenStats _getStatsForSong(String songId, String title, String artist) {
    final raw = _listenStatsBoxRef.get(songId);
    if (raw != null) {
      try {
        return ListenStats.fromJson(jsonDecode(raw.toString()));
      } catch (_) {}
    }
    return ListenStats(songId: songId, title: title, artist: artist);
  }

  Future<void> _updateListenStats(PlayEvent event) async {
    final stats = _getStatsForSong(event.songId, event.title, event.artist);
    stats.playCount++;
    stats.totalListened += event.listenedDuration;
    stats.totalDuration = event.totalDuration;
    stats.lastPlayed = DateTime.now().millisecondsSinceEpoch;
    await _saveStats(stats);
  }

  Future<void> _saveStats(ListenStats stats) async {
    final box = _listenStatsBoxRef;
    await box.put(stats.songId, jsonEncode(stats.toJson()));

    // Bound growth: evict least-recently-played non-favourites, keeping
    // favourites. Only triggers when a brand-new song pushes past the cap.
    if (box.length > _maxListenStats) {
      final entries = box.toMap().entries.map((e) {
        try {
          final s = ListenStats.fromJson(jsonDecode(e.value.toString()));
          return (e.key.toString(), s);
        } catch (_) {
          return (
            e.key.toString(),
            ListenStats(songId: e.key.toString(), title: '', artist: '')
          );
        }
      }).toList()
        ..sort((a, b) => a.$2.lastPlayed.compareTo(b.$2.lastPlayed));
      var overflow = box.length - _maxListenStats;
      for (final (key, s) in entries) {
        if (overflow <= 0) break;
        if (s.isFavourite) continue;
        await box.delete(key);
        overflow--;
      }
    }
  }
}
