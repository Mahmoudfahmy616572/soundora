import 'dart:io' show Directory, File, Platform;

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soundora/core/services/quran_resolver.dart';
import 'package:soundora/core/services/youtube_native.dart';
import 'package:soundora/core/services/resolved_url_cache.dart';
import 'package:soundora/core/services/offline_downloads.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/data/sources/jamendo/jamendo_data_source.dart';
import 'package:soundora/data/sources/deezer/deezer_data_source.dart';
import 'package:soundora/serviece_locator.dart';

import 'download_songs_for_offline_state.dart';

class DownloadSongsForOfflineCubit extends Cubit<DownloadSongsForOfflineState> {
  DownloadSongsForOfflineCubit()
      : super(DownloadSongsForOfflineLoaded(downloads: {}, completedIds: {}));

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(minutes: 5),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0 Safari/537.36',
    },
  ));
  final YoutubeNative _youtubeNative = YoutubeNative();
  Map<String, String> _resolveHeaders = const {};

  /// Directory where offline songs are stored. Uses the documents dir so the
  /// OS cannot purge downloads the way it does the cache dir.
  static Future<Directory> _downloadsDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/soundora_downloads');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Moves any downloads left in the old cache dir to the documents dir and
  /// updates the offline_songs box. Called once at app startup.
  static Future<void> migrateLegacyDownloads() async {
    try {
      final box = Hive.box('offline_songs');
      final newDir = await _downloadsDirectory();
      final cacheDir = await getApplicationCacheDirectory();
      final oldPrefix = '${cacheDir.path}${Platform.pathSeparator}';
      var changed = false;
      for (final key in box.keys.toList()) {
        final path = box.get(key)?.toString() ?? '';
        if (path.startsWith(oldPrefix) && await File(path).exists()) {
          final fileName = path.split(Platform.pathSeparator).last;
          final dest = '${newDir.path}${Platform.pathSeparator}$fileName';
          try {
            await File(path).rename(dest);
            await box.put(key, dest);
            changed = true;
          } catch (_) {
            try {
              await File(path).copy(dest);
              await File(path).delete();
              await box.put(key, dest);
              changed = true;
            } catch (_) {}
          }
        }
      }
      if (changed) {
        debugPrint(
            'downloadSongsForOffline: migrated legacy downloads to documents dir');
      }
    } catch (_) {}
  }

  /// Resolve the best full-song URL to download.
  ///
  /// Order matters:
  /// 1. Uploaded songs (Supabase storage) are already complete files.
  /// 2. Jamendo full CC audio â€” the same source used for playback, so the
  ///    downloaded song matches what the user is listening to.
  /// 3. YouTube (resolver backend) full audio for anything Jamendo does not
  ///    have.
  /// 4. Whatever the app is currently streaming (often a 30s preview).
  Future<String?> _resolveDownloadUrl(SongModel song) async {
    _resolveHeaders = const {};
    final direct = song.urlSongsbase;
    if (direct.isNotEmpty &&
        (direct.contains('supabase.co') || direct.contains('supabase'))) {
      debugPrint('downloadSongsForOffline: direct Supabase URL');
      return direct;
    }

    final quranUrl = QuranResolver.resolve(song);
    if (quranUrl != null) {
      debugPrint('downloadSongsForOffline: Quran full recitation $quranUrl');
      return quranUrl;
    }

    // Previously resolved full-song URL (persistent cache).
    final songKey = '${song.title}|${song.artist}';
    try {
      final cached = await ResolvedUrlCache.instance.get(songKey);
      if (cached != null) {
        _resolveHeaders = cached.headers;
        debugPrint('downloadSongsForOffline: cache hit $songKey -> ${cached.url}');
        return cached.url;
      }
    } catch (_) {}

    if (getIt.isRegistered<JamendoDataSource>()) {
      final jamendo = getIt<JamendoDataSource>();
      final title = song.title;
      final queries = [
        '$title ${song.artist}',
        title,
      ];
      for (final q in queries) {
        try {
          debugPrint('downloadSongsForOffline: Jamendo searching "$q"');
          final results = await jamendo
              .search(q, limit: 3)
              .timeout(const Duration(seconds: 5));
          if (results.isNotEmpty) {
            debugPrint('downloadSongsForOffline: Jamendo ${results.first.audioUrl}');
            return results.first.audioUrl;
          }
        } catch (e) {
          debugPrint('downloadSongsForOffline: Jamendo error $e');
        }
      }
    }

    try {
      debugPrint(
          'downloadSongsForOffline: YouTube (native innerTube) resolving "${song.title} ${song.artist}"');
      final track = await _youtubeNative
          .resolveBestAudio('${song.title} ${song.artist}');
      if (track != null && track.url.isNotEmpty) {
        _resolveHeaders = track.headers;
        try {
          await ResolvedUrlCache.instance
              .put(songKey, url: track.url, headers: track.headers, native: true);
        } catch (_) {}
        debugPrint(
            'downloadSongsForOffline: YouTube ${track.title} (${track.url})');
        return track.url;
      }
      debugPrint('downloadSongsForOffline: YouTube no result');
    } catch (e) {
      debugPrint('downloadSongsForOffline: YouTube error $e');
    }

    // Last resort: the stored stream URL (often a 30s Deezer preview).
    // Stored Deezer preview URLs expire, so re-fetch a fresh one first.
    if (direct.contains('dzcdn.net') && getIt.isRegistered<DeezerDataSource>()) {
      try {
        debugPrint('downloadSongsForOffline: Deezer preview URL may be expired, re-fetching...');
        final deezer = getIt<DeezerDataSource>();
        final fresh = await deezer.searchTracks(
          '${song.title} ${song.artist}',
          limit: 1,
        );
        if (fresh.isNotEmpty && fresh.first.urlSongsbase.isNotEmpty) {
          debugPrint('downloadSongsForOffline: Fresh Deezer URL obtained');
          return fresh.first.urlSongsbase;
        }
      } catch (e) {
        debugPrint('downloadSongsForOffline: Deezer re-fetch error $e');
      }
    }

    return direct.isNotEmpty ? direct : null;
  }

  Future<void> downloadSongsForOffline(SongModel songs) async {
    if (state is! DownloadSongsForOfflineLoaded) return;
    final currentState = state as DownloadSongsForOfflineLoaded;
    if (currentState.downloads.containsKey(songs.id)) {
      return;
    }
    // A valid file is already on disk (possibly expired entries are treated as
    // not downloaded, so the user can re-download them).
    final existingPath = await OfflineDownloads.pathOf(songs.id);
    if (existingPath != null) {
      return;
    }

    debugPrint('downloadSongsForOffline: START ${songs.title} (${songs.id})');

    // Show the spinner immediately while the URL is being resolved.
    final started = Map<String, double>.from(currentState.downloads);
    started[songs.id] = 0.01;
    emit(currentState.copyWith(downloads: started));

    try {
      final downloadUrl = await _resolveDownloadUrl(songs);
      if (downloadUrl == null) {
        debugPrint('downloadSongsForOffline: no URL resolved for ${songs.id}');
        emit(currentState.copyWith(
            downloads: Map<String, double>.from(started)..remove(songs.id)));
        return;
      }

      debugPrint('downloadSongsForOffline: downloading from $downloadUrl');

      final directory = await _downloadsDirectory();
      final String savePath = '${directory.path}/${songs.id}.mp3';
      // googlevideo URLs are signed for the resolver's IP, so relay them
      // through the backend which streams from that same IP (a direct request
      // from this device 403s, e.g. on the Android emulator).
      // Native googlevideo URLs (innerTube) are signed for this device's IP,
      // so they download directly â€” no backend relay needed.
      var dlUrl = downloadUrl;
      Map<String, String>? dlHeaders = _resolveHeaders.isNotEmpty
          ? _resolveHeaders
          : downloadUrl.contains('dzcdn.net')
              ? {
                  'Referer': 'https://deezer.com',
                  'Origin': 'https://deezer.com',
                }
              : null;
      final contentType = (await _downloadToFile(
        dlUrl,
        savePath,
        headers: dlHeaders,
        onProgress: (count, total) {
          if (total > 0 && state is DownloadSongsForOfflineLoaded) {
            final progress = count / total;
            final latestState = state as DownloadSongsForOfflineLoaded;
            final newDownloads = Map<String, double>.from(latestState.downloads);
            newDownloads[songs.id] = progress;

            emit(latestState.copyWith(downloads: newDownloads));
          }
        },
      )) ??
          '';

      var finalPath = savePath;
      if (contentType.contains('audio/webm')) {
        finalPath = '${directory.path}/${songs.id}.webm';
      } else if (contentType.contains('video/mp4') ||
          contentType.contains('audio/mp4') ||
          contentType.contains('audio/m4a')) {
        finalPath = '${directory.path}/${songs.id}.m4a';
      } else if (contentType.contains('audio/ogg')) {
        finalPath = '${directory.path}/${songs.id}.ogg';
      }
      if (finalPath != savePath && await File(finalPath).exists()) {
        await File(finalPath).delete();
      }
      if (finalPath != savePath) {
        await File(savePath).rename(finalPath);
      }
      if (state is DownloadSongsForOfflineLoaded) {
        final latestState = state as DownloadSongsForOfflineLoaded;
        final newDownloads = Map<String, double>.from(latestState.downloads);
        newDownloads.remove(songs.id);
        final newCompletedIds = Set<String>.from(latestState.completedIds);
        newCompletedIds.add(songs.id);
        await OfflineDownloads.register(songs.id, finalPath);
        final metaBox = Hive.box("songs_metadata");
        await metaBox.put(songs.id, songs.toJson());

        debugPrint('downloadSongsForOffline: DONE ${songs.title} -> $finalPath');

        emit(latestState.copyWith(
            downloads: newDownloads, completedIds: newCompletedIds));
      }
    } catch (e) {
      debugPrint('downloadSongsForOffline failed for ${songs.id}: $e');
      emit(currentState.copyWith(
          downloads: Map<String, double>.from(started)..remove(songs.id)));
    }
  }

  /// Downloads [url] to [savePath], using parallel Range requests for large
  /// files to beat the per-connection speed cap. Returns the response
  /// content-type (used to pick the right file extension).
  Future<String?> _downloadToFile(
    String url,
    String savePath, {
    Map<String, String>? headers,
    required void Function(int count, int total) onProgress,
  }) async {
    String? contentType;
    int? totalSize;

    // Probe the file: size + content-type, and confirm Range support.
    try {
      final probe = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {...?headers, 'Range': 'bytes=0-0'},
        ),
      );
      contentType = probe.headers.value('content-type');
      if (probe.statusCode == 206) {
        final cr = probe.headers.value('content-range');
        if (cr != null) {
          final m = RegExp(r'/(\d+)\s*$').firstMatch(cr);
          totalSize = m != null ? int.tryParse(m.group(1)!) : null;
        }
      }
      totalSize ??= int.tryParse(probe.headers.value('content-length') ?? '');
    } catch (_) {}

    Future<void> singleDownload() async {
      final resp = await _dio.download(
        url,
        savePath,
        options: Options(headers: headers),
        onReceiveProgress: (count, total) => onProgress(count, total),
      );
      contentType = resp.headers.value('content-type') ?? contentType;
    }

    if (totalSize == null || totalSize < 1024 * 1024) {
      await singleDownload();
      return contentType;
    }

    // Parallel chunked download (4 connections).
    final size = totalSize;
    const parts = 4;
    final partSize = (size / parts).ceil();
    final partPaths = <String>[];
    final partCounts = List<int>.filled(parts, 0);
    final futures = <Future<void>>[];

    for (var i = 0; i < parts; i++) {
      final start = i * partSize;
      if (start >= size) break;
      var end = start + partSize - 1;
      if (end >= size) end = size - 1;
      final partPath = '$savePath.part$i';
      partPaths.add(partPath);
      futures.add(_dio.download(
        url,
        partPath,
        options: Options(headers: {
          ...?headers,
          'Range': 'bytes=$start-$end',
        }),
        onReceiveProgress: (count, total) {
          partCounts[i] = count;
          final done = partCounts.fold<int>(0, (a, b) => a + b);
          onProgress(done.clamp(0, size).toInt(), size);
        },
      ));
    }

    try {
      await Future.wait(futures);
    } catch (_) {
      // Range rejected (e.g. server returns 200 for every part): fall back.
      for (final p in partPaths) {
        final f = File(p);
        if (await f.exists()) await f.delete();
      }
      await singleDownload();
      return contentType;
    }

    // Merge the parts into the final file.
    final out = File(savePath);
    final sink = out.openWrite();
    for (final p in partPaths) {
      sink.add(await File(p).readAsBytes());
      await File(p).delete();
    }
    await sink.close();
    return contentType;
  }

  @override
  Future<void> close() {
    _dio.close();
    _youtubeNative.close();
    return super.close();
  }
}
