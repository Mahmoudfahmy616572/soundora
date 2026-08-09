import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';

class LyricLine {
  final String text;
  final Duration startTime;

  /// True when the timestamps come from the exact audio source being played
  /// (innerTube lyrics for the resolved video id). Such timestamps are the
  /// ground truth and must not be re-aligned with DSP analysis.
  final bool exactMatch;

  LyricLine(this.text, this.startTime, {this.exactMatch = false});

  Map<String, dynamic> toJson() => {
        'text': text,
        'ms': startTime.inMilliseconds,
        'exact': exactMatch,
      };

  factory LyricLine.fromJson(Map<String, dynamic> json) => LyricLine(
        json['text'] as String? ?? '',
        Duration(milliseconds: (json['ms'] as num?)?.toInt() ?? 0),
        exactMatch: json['exact'] == true,
      );
}

abstract class LyricsDataSource {
  Future<List<LyricLine>> fetchSyncedLyrics({
    required String trackName,
    required String artistName,
    String videoId = '',
    int durationSeconds = 0,
  });

  Future<List<String>> fetchPlainLyrics({
    required String trackName,
    required String artistName,
  });

  Future<List<LyricLine>> fetchLyricsWithEmotion({
    required String trackName,
    required String artistName,
  });
}

class LyricsDataSourceImpl implements LyricsDataSource {
  final Dio _dio;
  final Box _cacheBox;

  static const String _lyricaBase = 'https://wilooper-lyrica.hf.space';
  static const String _lrclibBase = 'https://lrclib.net/api';
  static const String _innerTubeBase = 'https://music.youtube.com/youtubei/v1';
  static const String _lyricsPageType = 'MUSIC_PAGE_TYPE_TRACK_LYRICS';

  /// YouTube Music innerTube key, supplied via .env (YOUTUBE_INNERTUBE_KEY).
  static String get _innerTubeKey => dotenv.env['YOUTUBE_INNERTUBE_KEY'] ?? '';

  /// Cache schema version. Bumped to discard stale/wrongly-matched entries
  /// cached by older builds (the old race used to cache mismatched lyrics).
  static const int _cacheVersion = 2;

  static const _cacheTtl = Duration(days: 30);
  static const _cacheMaxEntries = 400;

  LyricsDataSourceImpl({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
            )),
        _cacheBox = Hive.box('lyrics_cache');

  /// Removes expired/oversized lyrics cache entries. Called at app startup.
  static Future<void> pruneCache() async {
    try {
      final box = Hive.box('lyrics_cache');
      final now = DateTime.now().millisecondsSinceEpoch;
      final expired = <dynamic>[];
      box.toMap().forEach((k, v) {
        if (v is Map) {
          final ts = (v['ts'] as int?) ?? 0;
          if (now - ts > _cacheTtl.inMilliseconds) expired.add(k);
        }
      });
      if (expired.isNotEmpty) await box.deleteAll(expired);

      if (box.length > _cacheMaxEntries) {
        final entries = box.toMap().entries.toList()
          ..sort((a, b) {
            final ta = a.value is Map
                ? ((a.value as Map)['ts'] as int?) ?? 0
                : 0;
            final tb = b.value is Map
                ? ((b.value as Map)['ts'] as int?) ?? 0
                : 0;
            return ta.compareTo(tb);
          });
        for (var i = 0; i < entries.length - _cacheMaxEntries; i++) {
          await box.delete(entries[i].key);
        }
      }
    } catch (_) {}
  }

  /// Key is the exact video id when known (so the correct innerTube result
  /// gets its own slot), otherwise the title/artist text pair.
  String _cacheKey(String track, String artist, String videoId) =>
      videoId.isNotEmpty
          ? 'vid_$videoId'
          : '${artist.toLowerCase().trim()}_${track.toLowerCase().trim()}';

  String get _lyricaUrl => dotenv.env['LYRICA_API_URL'] ?? _lyricaBase;

  @override
  Future<List<LyricLine>> fetchSyncedLyrics({
    required String trackName,
    required String artistName,
    String videoId = '',
    int durationSeconds = 0,
  }) async {
    final key = _cacheKey(trackName, artistName, videoId);
    final cached = _cacheBox.get(key);
    if (cached != null) {
      try {
        final cachedMap = cached is Map ? cached : {'data': cached};
        final ts = (cachedMap['ts'] as int?) ?? 0;
        final version = (cachedMap['v'] as int?) ?? 1;
        final fresh = version == _cacheVersion &&
            DateTime.now().millisecondsSinceEpoch - ts <=
                _cacheTtl.inMilliseconds;
        if (!fresh) {
          await _cacheBox.delete(key);
        } else {
          final json = cachedMap['data'] as String? ?? '';
          final list = (jsonDecode(json) as List)
              .map((e) => LyricLine.fromJson(e as Map<String, dynamic>))
              .toList();
          if (list.isNotEmpty) return list;
        }
      } catch (_) {}
    }

    // Priority: innerTube timed lyrics for the exact video being played first
    // (guaranteed to match text AND timing), then LRCLIB matched by title and
    // artist. No racing: a slow-but-correct source must not lose to a fast
    // source that matched the wrong song.
    var lyrics = <LyricLine>[];
    if (videoId.isNotEmpty) {
      lyrics = await _fetchFromInnerTube(videoId);
      // innerTube lines are tied to the exact video being played, so their
      // timestamps are ground truth — mark them so the player skips analysis.
      if (lyrics.isNotEmpty) {
        lyrics = lyrics
            .map((l) => LyricLine(l.text, l.startTime, exactMatch: true))
            .toList();
      }
    }
    if (lyrics.isEmpty) {
      lyrics = await _fetchFromLrclib(trackName, artistName, durationSeconds);
    }
    if (lyrics.isNotEmpty) {
      _cacheLyrics(key, lyrics);
    }

    return lyrics;
  }

  @override
  Future<List<String>> fetchPlainLyrics({
    required String trackName,
    required String artistName,
  }) async {
    try {
      final response = await _dio.get(
        '$_lyricaUrl/lyrics/',
        queryParameters: {
          'artist': artistName,
          'song': trackName,
          'timestamps': false,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success' && data['data'] != null) {
          final lyricsText = data['data']['lyrics'] as String?;
          if (lyricsText != null && lyricsText.isNotEmpty) {
            return lyricsText
                .split('\n')
                .where((l) => l.trim().isNotEmpty)
                .toList();
          }
        }
      }
    } catch (_) {}

    return [];
  }

  @override
  Future<List<LyricLine>> fetchLyricsWithEmotion({
    required String trackName,
    required String artistName,
  }) async {
    final lyrics = await fetchSyncedLyrics(
      trackName: trackName,
      artistName: artistName,
    );

    return lyrics;
  }

  /// YouTube's own timed lyrics (innerTube): watch `next` (WEB_REMIX) locates
  /// the lyrics page id, then a mobile `browse` (ANDROID_MUSIC) returns the
  /// timed lines. These are tied to the exact video id, so they always match
  /// the audio actually playing.
  Future<List<LyricLine>> _fetchFromInnerTube(String videoId) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      sendTimeout: const Duration(seconds: 8),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/'
            '537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'Origin': 'https://music.youtube.com',
      },
    ));
    try {
      final today = _youtubeDate();
      final next = await _innerTubePost(dio, 'next', {
        'context': {
          'client': {
            'clientName': 'WEB_REMIX',
            'clientVersion': '1.$today.01.00',
            'hl': 'en',
            'gl': 'US',
          },
        },
        'enablePersistentPlaylistPanel': true,
        'isAudioOnly': true,
        'tunerSettingValue': 'AUTOMIX_SETTING_NORMAL',
        'videoId': videoId,
        'playlistId': 'RDAMVM$videoId',
        'watchEndpointMusicSupportedConfigs': {
          'watchEndpointMusicConfig': {
            'hasPersistentPlaylistPanel': true,
            'musicVideoType': 'MUSIC_VIDEO_TYPE_ATV',
          },
        },
      });

      final browseId = findLyricsBrowseId(next);
      if (browseId == null || browseId.isEmpty) return const [];

      final browse = await _innerTubePost(dio, 'browse', {
        'context': {
          'client': {
            'clientName': 'ANDROID_MUSIC',
            'clientVersion': '6.20.58',
            'hl': 'en',
            'gl': 'US',
            'androidSdkVersion': 31,
          },
        },
        'browseId': browseId,
      });

      return parseTimedLyricsData(browse);
    } catch (_) {
      // innerTube is best-effort; LRCLIB covers the misses.
      return const [];
    } finally {
      dio.close(force: true);
    }
  }

  Future<dynamic> _innerTubePost(
    Dio dio,
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await dio.post(
      '$_innerTubeBase/$endpoint?key=$_innerTubeKey',
      data: body,
      options: Options(responseType: ResponseType.json),
    );
    return response.data;
  }

  /// LRCLIB synced lyrics, matched by artist/track (+ optional duration).
  ///
  /// The artist name is tried as-is and again transliterated (e.g. أديل ->
  /// Adele), since LRCLIB stores most non-Latin artists in Latin script.
  Future<List<LyricLine>> _fetchFromLrclib(
    String track,
    String artist,
    int durationSeconds,
  ) async {
    if (track.trim().isEmpty) return const [];

    final artists = <String>{artist};
    final latin = _latinArtist(artist);
    if (latin.isNotEmpty && latin != artist) artists.add(latin);

    for (final a in artists) {
      try {
        final response = await _dio.get(
          '$_lrclibBase/get',
          queryParameters: {
            'track_name': track,
            'artist_name': a,
            if (durationSeconds > 0) 'duration': durationSeconds,
          },
          options: Options(
            headers: {'Accept': 'application/json'},
          ),
        );
        if (response.statusCode == 200) {
          final data = response.data;
          final syncedLyrics = data['syncedLyrics'] as String?;
          if (syncedLyrics != null && syncedLyrics.isNotEmpty) {
            final parsed = _parseLrcLyrics(syncedLyrics);
            if (parsed.isNotEmpty) return parsed;
          }
        }
      } catch (_) {
        // HTTP 404 (no exact match) or a network error -> try the next name.
      }
    }

    return _searchLrclib(track, artist, durationSeconds);
  }

  /// LRCLIB search fallback: prefer non-instrumental, closest to the target
  /// duration. Only synced (timed) results are accepted.
  Future<List<LyricLine>> _searchLrclib(
    String track,
    String artist,
    int durationSeconds,
  ) async {
    try {
      final response = await _dio.get(
        '$_lrclibBase/search',
        queryParameters: {'track_name': track, 'artist_name': artist},
        options: Options(
          headers: {'Accept': 'application/json'},
        ),
      );
      final results = response.data;
      if (results is! List || results.isEmpty) return const [];

      results.sort((a, b) {
        if (a is! Map || b is! Map) return 0;
        final aInst = a['instrumental'] == true ? 1 : 0;
        final bInst = b['instrumental'] == true ? 1 : 0;
        if (aInst != bInst) return aInst.compareTo(bInst);
        if (durationSeconds > 0) {
          final aDur = (a['duration'] as num?)?.toDouble() ?? 0;
          final bDur = (b['duration'] as num?)?.toDouble() ?? 0;
          return ((aDur - durationSeconds).abs())
              .compareTo((bDur - durationSeconds).abs());
        }
        return 0;
      });

      for (final item in results) {
        if (item is Map && item['syncedLyrics'] is String) {
          final lrc = item['syncedLyrics'] as String;
          if (lrc.isNotEmpty) {
            final parsed = _parseLrcLyrics(lrc);
            if (parsed.isNotEmpty) return parsed;
          }
        }
      }
    } catch (_) {
      // LRCLIB is best-effort too; the UI shows "No Lyrics" when empty.
    }
    return const [];
  }

  /// Recursively finds the lyrics `browseId` (MPLYt...) inside a watch `next`
  /// response: a map holding a `browseId` whose subtree carries the
  /// `MUSIC_PAGE_TYPE_TRACK_LYRICS` page type.
  static String? findLyricsBrowseId(dynamic node) {
    if (node is Map<String, dynamic>) {
      final browseId = node['browseId'];
      if (browseId is String &&
          browseId.isNotEmpty &&
          _containsPageType(node, _lyricsPageType)) {
        return browseId;
      }
      for (final value in node.values) {
        final found = findLyricsBrowseId(value);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final item in node) {
        final found = findLyricsBrowseId(item);
        if (found != null) return found;
      }
    }
    return null;
  }

  static bool _containsPageType(dynamic node, String target) {
    if (node is Map<String, dynamic>) {
      if (node['pageType'] == target) return true;
      return node.values.any((v) => _containsPageType(v, target));
    }
    if (node is List) return node.any((v) => _containsPageType(v, target));
    return false;
  }

  /// Extracts timed lyric lines from a mobile lyrics `browse` response.
  static List<LyricLine> parseTimedLyricsData(dynamic data) {
    final lyricsData = _dig(data, [
      'contents',
      'elementRenderer',
      'newElement',
      'type',
      'componentType',
      'model',
      'timedLyricsModel',
      'lyricsData',
    ]);
    if (lyricsData is! Map<String, dynamic>) return const [];
    final raw = lyricsData['timedLyricsData'];
    if (raw is! List) return const [];

    final lines = <LyricLine>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final text = item['lyricLine']?.toString().trim() ?? '';
      final cue = item['cueRange'];
      if (text.isEmpty || cue is! Map<String, dynamic>) continue;
      final ms = int.tryParse('${cue['startTimeMilliseconds']}');
      if (ms == null) continue;
      lines.add(LyricLine(text, Duration(milliseconds: ms)));
    }
    return lines;
  }

  /// Parses LRC text (`[mm:ss.xx]` with 2-digit hundredths, or 3-digit
  /// milliseconds) into timed lyric lines.
  List<LyricLine> _parseLrcLyrics(String lrcContent) {
    final RegExp regExpMmSsMs = RegExp(r'\[(\d+):(\d+)\.(\d+)\](.*)');
    final RegExp regExpMmSs = RegExp(r'\[(\d+):(\d+)\](.*)');
    final List<LyricLine> lyrics = [];

    for (var line in lrcContent.split('\n')) {
      final match = regExpMmSsMs.firstMatch(line);
      if (match != null) {
        try {
          final minutes = int.parse(match.group(1)!);
          final seconds = int.parse(match.group(2)!);
          final rawMs = match.group(3)!;
          // "34" (2 digits) = hundredths -> 340ms, "345" = 345ms, "3" -> 300ms.
          final milliseconds = int.parse(rawMs.padRight(3, '0'));
          final text = match.group(4)?.trim() ?? '';

          if (text.isNotEmpty) {
            lyrics.add(LyricLine(
              text,
              Duration(
                minutes: minutes,
                seconds: seconds,
                milliseconds: milliseconds,
              ),
            ));
          }
        } catch (_) {}
        continue;
      }

      final matchSimple = regExpMmSs.firstMatch(line);
      if (matchSimple != null) {
        try {
          final minutes = int.parse(matchSimple.group(1)!);
          final seconds = int.parse(matchSimple.group(2)!);
          final text = matchSimple.group(3)?.trim() ?? '';

          if (text.isNotEmpty) {
            lyrics.add(LyricLine(
              text,
              Duration(
                minutes: minutes,
                seconds: seconds,
              ),
            ));
          }
        } catch (_) {}
      }
    }
    return lyrics;
  }

  void _cacheLyrics(String key, List<LyricLine> lyrics) {
    try {
      final json = jsonEncode(lyrics.map((l) => l.toJson()).toList());
      _cacheBox.put(key, {
        'v': _cacheVersion,
        'ts': DateTime.now().millisecondsSinceEpoch,
        'data': json,
      });
    } catch (_) {}
  }

  static dynamic _dig(dynamic node, List<String> path) {
    var current = node;
    for (final key in path) {
      if (current is Map<String, dynamic> && current[key] != null) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  static String _youtubeDate() {
    final now = DateTime.now().toUtc();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}$m$d';
  }

  /// Common Arabic artist names -> Latin (LRCLIB stores non-Latin artists in
  /// Latin script, so exact matches with the Arabic name always 404).
  static String _latinArtist(String artist) {
    const map = {
      'أديل': 'Adele',
      'ام كلثوم': 'Um Kalthoum',
      'أم كلثوم': 'Um Kalthoum',
      'عمرو دياب': 'Amr Diab',
      'تامر حسني': 'Tamer Hosny',
      'محمد منير': 'Mohamed Mounir',
      'محمد حماقي': 'Mohamed Hamaki',
      'محمد رمضان': 'Mohamed Ramadan',
      'كايروكي': 'Cairokee',
      'حمزة نمرة': 'Hamza Namira',
      'شيرين': 'Sherine',
      'أصالة': 'Assala',
      'اصالة': 'Assala',
      'رامي صبري': 'Ramy Sabry',
      'أنغام': 'Angham',
      'انغام': 'Angham',
      'هشام عباس': 'Hisham Abbas',
      'نانسي عجرم': 'Nancy Ajram',
      'اليسا': 'Elissa',
      'إليسا': 'Elissa',
      'فيروز': 'Fairuz',
      'فريد الأطرش': 'Farid Al Atrash',
      'عبد الحليم حافظ': 'Abdel Halim Hafez',
      'محمد عبد الوهاب': 'Mohamed Abdel Wahab',
      'كاظم الساهر': 'Kazem Al Saher',
      'حسين الجسمي': 'Hussain Al Jassmi',
      'عاصي الحلاني': 'Assi El Hallani',
      'ماجد المهندس': 'Majid Al Mohandis',
      'أحمد سعد': 'Ahmed Saad',
      'تامر عاشور': 'Tamer Ashour',
      'بهاء سلطان': 'Bahaa Sultan',
      'سعد لمجرد': 'Saad Lamjarred',
      'جورج وسوف': 'George Wassouf',
      'راغب علامة': 'Ragheb Alama',
      'وائل كفوري': 'Wael Kfoury',
      'نوال الزغبي': 'Nawal Al Zoghbi',
      'ميريام فارس': 'Myriam Fares',
      'حكيم': 'Hakim',
      'مدحت صالح': 'Medhat Saleh',
      'لطيفة': 'Latifa',
      'هايفا وهبي': 'Haifa Wehbe',
    };
    final trimmed = artist.trim();
    return map[trimmed] ?? '';
  }
}
