// ignore_for_file: avoid_print, experimental_member_use
import 'dart:async';
import 'dart:io' show File;
import 'dart:isolate';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soundora/core/services/lyric_alignment.dart';
import 'package:soundora/core/services/sync_analyzer.dart';
import 'package:soundora/core/services/sync_offset_cache.dart';
import 'package:soundora/core/services/maqam_detector.dart';
import 'package:soundora/core/services/quran_resolver.dart';
import 'package:soundora/core/services/youtube_native.dart';
import 'package:soundora/core/services/resolved_url_cache.dart';
import 'package:soundora/core/services/offline_downloads.dart';
import 'package:soundora/data/sources/jamendo/jamendo_data_source.dart';
import 'package:soundora/data/sources/deezer/deezer_data_source.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/data/sources/listening_history/listening_data_source.dart';
import 'package:soundora/presentation/LyricsMemory/cubit/lyrics_memory_cubit.dart';
import 'package:soundora/serviece_locator.dart';

import 'lyrics/lyrics_cubit.dart';
import 'lyrics/lyrics_state.dart';
import 'song_player_state.dart';

class SongPlayerCubit extends Cubit<SongPlayerState> with WidgetsBindingObserver {
  static const MethodChannel _audioDecoderChannel = MethodChannel('audio_decoder');
  bool _isShuffleMode = false;
  bool get isShuffleMode => _isShuffleMode;
  LoopMode _loopMode = LoopMode.off;
  LoopMode get loopMode => _loopMode;
  bool _isLyricsVisible = false;
  bool _showFullSongPopup = false;
  bool _fullSongResolving = false;
  bool _isUpgrading = false;
  bool _isAppInForeground = true;
  bool _suppressPopupForSession = false;
  bool _autoSwapDisabled = false;
  int _fullSongPromptIgnores = 0;
  Timer? _fullSongBannerTimer;
  Completer<void>? _fullSongResolvedCompleter;
  String? _pendingFullUrl;
  Map<String, String> _pendingFullHeaders = const {};
  final AudioPlayer audioPlayer = AudioPlayer();
  final Dio _dio = Dio(BaseOptions(
    headers: {
      'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36',
    },
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(minutes: 5),
  ));
  List<SongModel> _playList = [];
  int _currentIndex = 0;
  String _url = '';
  bool _isFullSong = false;
  Duration _songDuration = Duration.zero;
  Duration _songPosition = Duration.zero;
  Color _dominantColor = const Color(0xff121212);
  Function(SongModel)? onSongPlayed;
  LyricsCubit? _lyricsCubit;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  SongModel? _previousSong;
  DateTime? _songStartedAt;
  bool _songFullyListened = false;
  Timer? _listenDurationTimer;
  final SyncOffsetCache _offsetCache = SyncOffsetCache();
  SyncAnalyzer? _analyzer;
  MaqamResult? _currentMaqam;
  final Map<String, MaqamResult> _maqamCache = {};

  /// The audio source currently loaded in [audioPlayer]. Empty when the audio
  /// came from a local file (offline).
  String _currentPlayUrl = '';
  Map<String, String> _currentPlayHeaders = const {};

  /// Song id analysis is currently running for (single-flight per song).
  String _analyzingSongId = '';
  /// Song id that lyrics alignment is being requested for.
  String _analysisRequestedForSong = '';
  bool _lyricsSubscribed = false;
  LyricAlignment? _alignment;

  List<SongModel> get playList => _playList;
  int get currentIndex => _currentIndex;
  Duration get songDuration => _songDuration;
  Duration get songPosition => _songPosition;
  Color get dominantColor => _dominantColor;
  MaqamResult? get currentMaqam => _currentMaqam;

  SongPlayerCubit({LyricsCubit? lyricsCubit})
      : _lyricsCubit = lyricsCubit,
        super(const SongPlayerLoading()) {
    WidgetsBinding.instance.addObserver(this);
    _subscriptions.add(audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        _songDuration = duration;
        _checkPreviewAndShowPopup();
        _emitCurrentState();
      }
    }));
    _subscriptions.add(audioPlayer.positionStream.listen((position) {
      _songPosition = position;
      _checkPreviewAndShowPopup();
      _emitCurrentState();
    }));
    _subscriptions.add(audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_showFullSongPopup) return;
        _songFullyListened = true;
        _recordFinalListenDuration();
        playNext();
      }
    }));
    _listenLyricsState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
    if (!_isAppInForeground) {
      // Nothing can be seen or tapped while locked/backgrounded â€” drop any
      // stale banner so it does not linger when the user comes back.
      _fullSongBannerTimer?.cancel();
      if (_showFullSongPopup) {
        _showFullSongPopup = false;
        _emitCurrentState();
      }
    }
  }

  /// Re-runs the full-song alignment whenever lyrics finish loading, using the
  /// currently playing (full) audio source.
  void _listenLyricsState() {
    final cubit = _lyricsCubit;
    if (cubit == null || _lyricsSubscribed) return;
    _lyricsSubscribed = true;
    _subscriptions.add(cubit.stream.listen((lyricsState) {
      if (lyricsState is LyricsLoaded && !isClosed) {
        _triggerAnalysis(_analysisRequestedForSong);
      }
    }));
  }

  void setLyricsCubit(LyricsCubit cubit) {
    _lyricsCubit = cubit;
    _listenLyricsState();
  }

  void _emitCurrentState() {
    if (!isClosed) {
      emit(SongPlayerLoaded(
        isLyricsVisible: _isLyricsVisible,
        showFullSongPopup: _showFullSongPopup,
        fullSongResolving: _fullSongResolving,
        isFullSong: _isFullSong,
        alignment: _alignment,
        currentIndex: _currentIndex,
        playlist: List.unmodifiable(_playList),
        isPlaying: audioPlayer.playing,
        songPosition: _songPosition,
        songDuration: _songDuration,
        dominantColor: _dominantColor,
      ));
    }
  }

  bool get canPlayFullSong =>
      _isFullSong || (_pendingFullUrl?.isNotEmpty ?? false);

  void _trackSkipIfNeeded() {
    if (_previousSong == null || _songStartedAt == null) return;

    final listened = DateTime.now().difference(_songStartedAt!);
    if (listened.inSeconds < 15 && !_songFullyListened) {
      try {
        final ds = getIt<ListeningDataSource>();
        ds.recordSkip(
          _previousSong!.id,
          _previousSong!.title,
          _previousSong!.artist,
          listened,
        );
      } catch (_) {}
    }

    if (_previousSong != null && _songStartedAt != null) {
      try {
        final ds = getIt<ListeningDataSource>();
        final listened = DateTime.now().difference(_songStartedAt!);
        ds.recordListenDuration(
          _previousSong!.id,
          _previousSong!.title,
          _previousSong!.artist,
          listened,
          _songDuration,
        );
      } catch (_) {}
    }
  }

  void _recordPlayEvent(SongModel song, {bool wasSkipped = false}) {
    try {
      final ds = getIt<ListeningDataSource>();
      final listened = _songStartedAt != null
          ? DateTime.now().difference(_songStartedAt!)
          : Duration.zero;
      ds.recordPlayEvent(PlayEvent(
        songId: song.id,
        title: song.title,
        artist: song.artist,
        timestamp: DateTime.now(),
        listenedDuration: listened,
        totalDuration: _songDuration,
        wasSkipped: wasSkipped,
      ));
    } catch (_) {}
  }

  /// Feeds the Lyrics Memory feature so its "journey" reflects what the user
  /// actually plays. Safe no-op when the memory cubit is unavailable.
  void _trackLyricsMemory(SongModel song) {
    try {
      getIt<LyricsMemoryCubit>().recordPlay(
        song.id.toString(),
        song.title,
        song.artist,
        song.imageUrl,
      );
    } catch (_) {}
  }

  void _recordFinalListenDuration() {
    if (_previousSong == null || _songStartedAt == null) return;
    try {
      final ds = getIt<ListeningDataSource>();
      final listened = DateTime.now().difference(_songStartedAt!);
      ds.recordListenDuration(
        _previousSong!.id,
        _previousSong!.title,
        _previousSong!.artist,
        listened,
        _songDuration,
      );
    } catch (_) {}
  }

  void _checkPreviewAndShowPopup() {
    if (!_isUpgrading || _showFullSongPopup) return;
    if (!_isAppInForeground || _suppressPopupForSession) return;
    if (_songDuration <= Duration.zero) return;
    final remaining = _songDuration - _songPosition;
    if (remaining > Duration.zero &&
        remaining <= const Duration(seconds: 6)) {
      _triggerFullSongPopup();
    }
  }

  /// Shows the "full song" banner on top of a playing preview. Non-blocking:
  /// the preview keeps playing and the banner auto-dismisses after a few
  /// seconds unless the user acts on it.
  void _triggerFullSongPopup() {
    if (_showFullSongPopup) return;
    _showFullSongPopup = true;
    _autoSwapDisabled = true;
    _fullSongResolvedCompleter ??= Completer<void>();
    _emitCurrentState();
    _fullSongBannerTimer?.cancel();
    _fullSongBannerTimer = Timer(const Duration(milliseconds: 4500), () {
      if (_showFullSongPopup) dismissFullSongPopup();
    });
  }

  void _hideFullSongPopup() {
    _fullSongBannerTimer?.cancel();
    _showFullSongPopup = false;
    _emitCurrentState();
  }

  void dismissFullSongPopup() {
    _fullSongBannerTimer?.cancel();
    _showFullSongPopup = false;
    // Two consecutive dismissals (auto or manual) mean the user is not
    // interested â€” stop offering the banner for the rest of the session.
    _fullSongPromptIgnores++;
    if (_fullSongPromptIgnores >= 2) {
      _suppressPopupForSession = true;
    }
    _emitCurrentState();
    // The preview already finished and the user does not want the full song â€”
    // move on to the next track instead of staying stuck at the end.
    if (audioPlayer.processingState == ProcessingState.completed) {
      _songFullyListened = true;
      _recordFinalListenDuration();
      playNext();
    }
  }

  Future<void> resolveFullSong() async {
    _fullSongBannerTimer?.cancel();
    _fullSongPromptIgnores = 0;
    _suppressPopupForSession = false;

    var fullUrl = _pendingFullUrl;
    if (fullUrl == null || fullUrl.isEmpty) {
      // Already upgraded automatically in the background â€” nothing to do.
      if (_isFullSong) {
        _showFullSongPopup = false;
        _fullSongResolving = false;
        _emitCurrentState();
        return;
      }
      // Wait for (or start) the background resolution, showing a spinner.
      if (!_isUpgrading && _playList.isNotEmpty) {
        final song = _playList[_currentIndex];
        final songKey = '${song.title}|${song.artist}';
        unawaited(_resolveAndUpgradeToFull(song, songKey, _playGeneration));
      }
      _fullSongResolvedCompleter ??= Completer<void>();
      final completer = _fullSongResolvedCompleter!;
      _fullSongResolving = true;
      _emitCurrentState();
      try {
        await completer.future.timeout(const Duration(seconds: 30));
      } on TimeoutException {
        // Give up waiting; fall through to the "no full source" path.
      }
      _fullSongResolving = false;
      fullUrl = _pendingFullUrl;
      if (fullUrl == null || fullUrl.isEmpty) {
        _showFullSongPopup = false;
        _emitCurrentState();
        if (audioPlayer.processingState == ProcessingState.completed) {
          _songFullyListened = true;
          _recordFinalListenDuration();
          playNext();
        } else {
          audioPlayer.play();
          _emitCurrentState();
        }
        return;
      }
    }
    _pendingFullUrl = null;
    final headers = _pendingFullHeaders;
    _pendingFullHeaders = const {};
    _showFullSongPopup = false;
    _fullSongResolving = false;
    _emitCurrentState();
    print('[UPGRADE] Popup accepted -> full song from start');
    _isFullSong = !fullUrl.contains('dzcdn.net');
    // All resolved sources (native innerTube googlevideo, Jamendo, mp3quran)
    // are directly streamable from the device â€” no backend relay or gating.
    final streamUrl = fullUrl;
    final streamHeaders = headers;
    _currentPlayUrl = streamUrl;
    _currentPlayHeaders = streamHeaders;
    await audioPlayer
        .setAudioSource(_dioAudioSource(streamUrl, headers: streamHeaders));
    audioPlayer.play();
    _emitCurrentState();
    _triggerAnalysis(_analysisRequestedForSong,
        audioUrl: streamUrl, audioHeaders: streamHeaders);
  }

  void toggleShowLyrics() {
    _isLyricsVisible = !_isLyricsVisible;
    _emitCurrentState();
  }

  void setLyricsVisible(bool visible) {
    _isLyricsVisible = visible;
    _emitCurrentState();
  }

  void updatePlaylist(List<SongModel> newPlaylist) {
    _playList = newPlaylist;
    _emitCurrentState();
  }

  void toggleShuffleMode() async {
    _isShuffleMode = !_isShuffleMode;
    await audioPlayer.setShuffleModeEnabled(_isShuffleMode);
    if (_isShuffleMode) {
      await audioPlayer.shuffle();
    }
    _emitCurrentState();
  }

  void toggleRepeatMode() {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.one;
    } else if (_loopMode == LoopMode.one) {
      _loopMode = LoopMode.all;
    } else {
      _loopMode = LoopMode.off;
    }
    audioPlayer.setLoopMode(_loopMode);
    _emitCurrentState();
  }

  Future<void> upDateThemeColor(String imageUrl) async {
    final uri = Uri.tryParse(imageUrl);
    if (imageUrl.isEmpty || uri == null || uri.host.isEmpty) {
      _dominantColor = const Color(0xff121212);
      _emitCurrentState();
      return;
    }
    try {
      PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        maximumColorCount: 10,
      );
      _dominantColor =
          paletteGenerator.dominantColor?.color ?? const Color(0xff121212);
    } catch (e) {
      _dominantColor = const Color(0xff121212);
    }
    _emitCurrentState();
  }

  void _autoFetchLyrics(SongModel song, {String? forcedVideoId}) {
    if (_lyricsCubit != null && !_lyricsCubit!.isClosed) {
      final songKey = '${song.title}|${song.artist}';
      _lyricsCubit!.fetchLyrics(
        trackName: song.title,
        artistName: song.artist,
        videoId: forcedVideoId ?? (_resolvedVideoIds[songKey] ?? ''),
        durationSeconds: _durationSeconds(song.duration),
      );
    }
  }

  /// Re-fetches lyrics once the native YouTube resolve knows the exact video
  /// id â€” innerTube lyrics are tied to that video, so text and timing always
  /// match what is playing.
  void _refetchLyricsForVideoId(SongModel song, String? videoId) {
    if (videoId == null || videoId.isEmpty) return;
    if (_lyricsCubit == null || _lyricsCubit!.isClosed) return;
    final songKey = '${song.title}|${song.artist}';
    _resolvedVideoIds[songKey] = videoId;
    _lyricsCubit!.fetchLyrics(
      trackName: song.title,
      artistName: song.artist,
      videoId: videoId,
      durationSeconds: _durationSeconds(song.duration),
    );
  }

  /// Parses the `m:ss` / `h:mm:ss` duration string stored on a song.
  int _durationSeconds(String duration) {
    final parts = duration.split(':');
    if (parts.isEmpty) return 0;
    final seconds = int.tryParse(parts.last) ?? 0;
    if (parts.length == 1) return seconds;
    final minutes = int.tryParse(parts[parts.length - 2]) ?? 0;
    final hours = parts.length >= 3 ? (int.tryParse(parts.first) ?? 0) : 0;
    return hours * 3600 + minutes * 60 + seconds;
  }

  final Map<String, String> _jamendoCache = {};
  /// YouTube video ids resolved natively per song key, used to fetch the
  /// exact synced lyrics (innerTube) for the video actually playing.
  final Map<String, String> _resolvedVideoIds = {};
  final YoutubeNative _youtubeNative = YoutubeNative();
  /// True when a native googlevideo URL has passed (or is about to pass) its
  /// `expire=` timestamp. Expired URLs always return 403, so they must never be
  /// reused from cache â€” always re-resolve them.
  static bool _nativeUrlExpired(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return true;
    final expire = uri.queryParameters['expire'];
    if (expire == null) return false;
    final exp = int.tryParse(expire);
    if (exp == null) return false;
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return exp <= nowSec + 300;
  }

  final Map<String, Map<String, String>> _ytHeadersByUrl = {};
  /// googlevideo URLs obtained directly from the device (innerTube API). They
  /// are signed for this device's IP and play without the backend relay.
  final Set<String> _nativeUrls = {};
  int _playGeneration = 0;

  static const int _maxMemoryResolutions = 200;

  /// Remembers a resolved URL in memory, evicting the oldest entry so a long
  /// session does not grow the maps without bound.
  void _rememberUrl(String songKey, String url,
      {Map<String, String> headers = const {}, bool native = false}) {
    if (_jamendoCache.length >= _maxMemoryResolutions) {
      _jamendoCache.remove(_jamendoCache.keys.first);
    }
    _jamendoCache[songKey] = url;
    if (native) _nativeUrls.add(url);
    if (headers.isNotEmpty) {
      if (_ytHeadersByUrl.length >= _maxMemoryResolutions) {
        _ytHeadersByUrl.remove(_ytHeadersByUrl.keys.first);
      }
      _ytHeadersByUrl[url] = headers;
    }
  }

  StreamAudioSource _dioAudioSource(String url, {Map<String, String>? headers}) {
    return _DioStreamAudioSource(_dio, url, headers);
  }

  Future<void> loadSong(
      List<SongModel> songs, int index, String urlImage, {bool skipLoadingEmit = false}) async {
    _trackSkipIfNeeded();
    _listenDurationTimer?.cancel();

    final previousSong = _playList.isNotEmpty && _currentIndex < _playList.length
        ? _playList[_currentIndex]
        : null;
    if (previousSong != null && _songStartedAt != null) {
      _recordPlayEvent(previousSong, wasSkipped: true);
    }

    _previousSong = songs[index];
    _songStartedAt = DateTime.now();
    _songFullyListened = false;
    _showFullSongPopup = false;
    _fullSongBannerTimer?.cancel();
    _fullSongBannerTimer = null;
    _fullSongResolving = false;
    _fullSongResolvedCompleter = null;
    _autoSwapDisabled = false;
    _isUpgrading = false;
    _pendingFullUrl = null;
    _pendingFullHeaders = const {};
    _isFullSong = false;

    _playList = songs;
    _currentIndex = index;
    _url = urlImage;
    upDateThemeColor(songs[index].imageUrl);
    onSongPlayed?.call(songs[index]);
    _trackLyricsMemory(songs[index]);

    // A local offline file is not necessarily the same recording as the
    // resolved YouTube video, so its lyrics must never be treated as exact.
    final String? localPath =
        await OfflineDownloads.pathOf(songs[index].id.toString());
    _autoFetchLyrics(songs[index],
        forcedVideoId: localPath != null ? '' : null);

    try {
      if (!skipLoadingEmit) emit(const SongPlayerLoaded(isLyricsVisible: false, isFullSong: false));
      String? streamUrl;
      Map<String, String>? streamHeaders;
      bool upgradeInBackground = false;
      bool backgroundSwapStarted = false;
      bool isNativeUrl = false;
      final playGen = ++_playGeneration;
      final song = songs[_currentIndex];
      final songKey = '${song.title}|${song.artist}';
      if (localPath != null && await File(localPath).exists()) {
        print('[PLAY] Offline: ${songs[_currentIndex].title}');
        _isFullSong = true;
        _currentPlayUrl = localPath;
        _currentPlayHeaders = const {};
        await audioPlayer.setFilePath(localPath);
      } else {
        // â”€â”€ 0. Instant: known URL from memory cache â”€â”€
        if (_jamendoCache.containsKey(songKey)) {
          streamUrl = _jamendoCache[songKey];
          streamHeaders =
              streamUrl != null ? _ytHeadersByUrl[streamUrl] : null;
          isNativeUrl = streamUrl != null && _nativeUrls.contains(streamUrl);
          if (streamUrl != null && _nativeUrlExpired(streamUrl)) {
            print('[CACHE] In-memory native URL expired: ${song.title}');
            _jamendoCache.remove(songKey);
            streamUrl = null;
            streamHeaders = null;
            isNativeUrl = false;
          } else if (streamUrl != null) {
            print('[CACHE] In-memory hit: ${song.title}');
          }
        } else {
          // â”€â”€ 0.1 Instant: persistent Hive cache â”€â”€
          try {
            final cached = await ResolvedUrlCache.instance.get(songKey);
            if (cached != null) {
              if (cached.native && _nativeUrlExpired(cached.url)) {
                print('[CACHE] Hive native URL expired, re-resolving: ${song.title}');
                try {
                  await ResolvedUrlCache.instance.remove(songKey);
                } catch (_) {}
              } else {
                streamUrl = cached.url;
                streamHeaders = cached.headers;
                isNativeUrl = cached.native;
                _rememberUrl(songKey, cached.url,
                    headers: cached.headers, native: cached.native);
                // Restore the video id so lyrics come from innerTube (exact
                // match) for the video that is actually going to play.
                final cachedVideoId = cached.videoId;
                if (cachedVideoId != null && cachedVideoId.isNotEmpty) {
                  _resolvedVideoIds[songKey] = cachedVideoId;
                  _refetchLyricsForVideoId(song, cachedVideoId);
                }
                print('[CACHE] Hive hit: ${song.title}');
              }
            }
          } catch (_) {}
        }

        // â”€â”€ 1. Quran surah (instant, no network) â”€â”€
        if (streamUrl == null) {
          final quranUrl = QuranResolver.resolve(song);
          if (quranUrl != null) {
            streamUrl = quranUrl;
            print('[QURAN] Full recitation: ${song.title}');
          }
        }

        if (streamUrl != null && streamUrl.isNotEmpty) {
          if (streamUrl.contains('googlevideo.com') && !isNativeUrl) {
            // Stale URL left over from the removed backend resolver (signed
            // for the backend's IP, 403s from the device). Play the preview
            // and re-resolve the full song natively (innerTube) in the
            // background.
            final fallbackUrl = song.urlSongsbase;
            final fallbackUri = Uri.tryParse(fallbackUrl);
            if (fallbackUrl.isEmpty ||
                fallbackUri == null ||
                fallbackUri.host.isEmpty) {
              print('[PLAY] No fallback URL for ${song.title}');
              throw Exception('No playable URL');
            }
            print('[PLAY] Preview until native full ready: ${song.title}');
            _isFullSong = !fallbackUrl.contains('dzcdn.net');
            _currentPlayUrl = fallbackUrl;
            _currentPlayHeaders = const {};
            await audioPlayer.setAudioSource(_dioAudioSource(fallbackUrl));
            upgradeInBackground = true;
            backgroundSwapStarted = true;
            unawaited(_resolveAndUpgradeToFull(song, songKey, playGen));
          } else {
            // Direct full URL (no backend involved) â€” play it immediately.
            print('[PLAY] Full song: ${song.title}');
            _isFullSong = !streamUrl.contains('dzcdn.net');
            _currentPlayUrl = streamUrl;
            _currentPlayHeaders = streamHeaders ?? const {};
            await audioPlayer.setAudioSource(
                _dioAudioSource(streamUrl, headers: streamHeaders ?? const {}));
          }
        } else {
          // Play the stored URL (often a preview) instantly; upgrade in background.
          final songUrl = song.urlSongsbase;
          final uri = Uri.tryParse(songUrl);
          if (songUrl.isEmpty || uri == null || uri.host.isEmpty) {
            print('[PLAY] No playable URL for ${song.title}');
            throw Exception('No playable URL');
          }
          print('[PLAY] Preview (Deezer): ${song.title}');
          _isFullSong = !songUrl.contains('dzcdn.net');
          _currentPlayUrl = songUrl;
          _currentPlayHeaders = const {};
          await audioPlayer.setAudioSource(_dioAudioSource(songUrl));
          upgradeInBackground = true;
        }
      }
      _loadSyncOffset(song.id.toString(),
          forFullSong: _isFullSong, sourceKey: _fingerprintFor(_currentPlayUrl,
              videoId: _currentVideoId()));
      audioPlayer.play();
      _emitCurrentState();
      if (upgradeInBackground) {
        // Preview keeps playing; offer the full song right away when the app
        // is visible (never on a locked/backgrounded phone, and never when the
        // user already dismissed the banner twice this session).
        if (_isAppInForeground && !_suppressPopupForSession) {
          _triggerFullSongPopup();
        }
        if (!backgroundSwapStarted) {
          _resolveAndUpgradeToFull(song, songKey, playGen);
        }
      }
      _preloadNextSong();
    } on Exception catch (e) {
      print('[PLAY] Failed: $e');
      final song = songs[_currentIndex];
      final isOldDeezer = song.urlSongsbase.contains('dzcdn.net');
      if (isOldDeezer && getIt.isRegistered<DeezerDataSource>()) {
        print('[PLAY] Deezer URL expired, re-fetching...');
        try {
          final deezer = getIt<DeezerDataSource>();
          final fresh = await deezer.searchTracks(
            '${song.title} ${song.artist}',
            limit: 1,
          );
          if (fresh.isNotEmpty && fresh.first.urlSongsbase.isNotEmpty) {
            print('[PLAY] Fresh Deezer URL obtained');
            _isFullSong = false;
            _currentPlayUrl = fresh.first.urlSongsbase;
            _currentPlayHeaders = const {};
            await audioPlayer.setAudioSource(_dioAudioSource(fresh.first.urlSongsbase));
            audioPlayer.play();
            _emitCurrentState();
            _preloadNextSong();
            return;
          }
        } catch (_) {}
      }
      emit(SongPlayerFailure(errorMessage: 'Failed to load song'));
    }
  }

  /// Resolve the best full-song source in the background and swap to it (from
  /// the start) when found, racing Jamendo (fast) against YouTube (slower). If
  /// the preview is about to end before anything resolves, a "full song ready"
  /// popup is shown instead and the user starts it from [resolveFullSong].
  Future<void> _resolveAndUpgradeToFull(
      SongModel song, String songKey, int playGen) async {
    _isUpgrading = true;
    _pendingFullUrl = null;
    _pendingFullHeaders = const {};

    final result = await _firstNonNull([
      _safeSearch(_searchJamendo(song), const Duration(seconds: 5)),
      _safeSearch(_searchYouTube(song), const Duration(seconds: 25)),
    ]);
    _isUpgrading = false;

    // The user moved on to another song â€” discard the result.
    if (playGen != _playGeneration) return;

    if (result == null || result.url.contains('dzcdn.net')) {
      if (_showFullSongPopup) _hideFullSongPopup();
      if (result == null) print('[UPGRADE] No full source found');
      return;
    }

    _rememberUrl(songKey, result.url, headers: result.headers, native: result.native);
    if (result.native) _refetchLyricsForVideoId(song, result.videoId);
    try {
      await ResolvedUrlCache.instance.put(songKey,
          url: result.url,
          headers: result.headers,
          native: result.native,
          videoId: result.videoId);
    } catch (_) {}

    // The banner is up (or was up and the user chose not to swap) â€” park the
    // URL for the play button instead of interrupting the preview.
    if (_showFullSongPopup || _autoSwapDisabled) {
      _pendingFullUrl = result.url;
      _pendingFullHeaders = result.headers;
      _fullSongResolvedCompleter?.complete();
      _fullSongResolvedCompleter = null;
      print('[UPGRADE] Ready (parked): ${song.title}');
      return;
    }

    print('[UPGRADE] ${result.source} -> ${song.title}');
    _isFullSong = true;
    // All resolved sources are directly streamable from the device â€” no
    // backend relay or gating.
    final streamUrl = result.url;
    final streamHeaders = result.headers;
    _currentPlayUrl = streamUrl;
    _currentPlayHeaders = streamHeaders;
    await audioPlayer
        .setAudioSource(_dioAudioSource(streamUrl, headers: streamHeaders));
    audioPlayer.play();
    _emitCurrentState();
    _fullSongResolvedCompleter?.complete();
    _fullSongResolvedCompleter = null;
    _triggerAnalysis(_analysisRequestedForSong,
        audioUrl: streamUrl, audioHeaders: streamHeaders);
  }

  Future<_ResolvedAudio?> _searchJamendo(SongModel song) async {
    if (!getIt.isRegistered<JamendoDataSource>()) return null;
    try {
      print('[JAMENDO] Searching: ${song.title} - ${song.artist}');
      final results = await getIt<JamendoDataSource>()
          .search('${song.title} ${song.artist}', limit: 3);
      if (results.isNotEmpty && results.first.audioUrl.isNotEmpty) {
        return _ResolvedAudio(results.first.audioUrl, const {}, 'JAMENDO');
      }
      print('[JAMENDO] No results');
    } catch (e) {
      print('[JAMENDO] Error: $e');
    }
    return null;
  }

  Future<_ResolvedAudio?> _searchYouTube(SongModel song) async {
    // Native innerTube extraction straight from the device (home/residential
    // IP) â€” no backend, cookies or account involved.
    try {
      print('[YT] Native resolve: ${song.title}');
      final track = await _youtubeNative
          .resolveBestAudio('${song.title} ${song.artist}');
      if (track != null && track.url.isNotEmpty) {
        print('[YT] Native full audio: ${track.title}');
        return _ResolvedAudio(track.url, track.headers, 'YT',
            native: true, videoId: track.videoId);
      }
      print('[YT] Native failed');
    } catch (e) {
      print('[YT] Native error: $e');
    }
    return null;
  }

  Future<_ResolvedAudio?> _safeSearch(
      Future<_ResolvedAudio?> search, Duration timeout) {
    return search.timeout(timeout).catchError((_) => null);
  }

  Future<_ResolvedAudio?> _firstNonNull(
      List<Future<_ResolvedAudio?>> futures) async {
    final completer = Completer<_ResolvedAudio?>();
    for (final f in futures) {
      unawaited(f.then((v) {
        if (!completer.isCompleted && v != null) completer.complete(v);
      }));
    }
    unawaited(Future.wait(futures).then((_) {
      if (!completer.isCompleted) completer.complete(null);
    }));
    return completer.future;
  }

  Future<void> _preloadNextSong() async {
    final nextIndex = _currentIndex < _playList.length - 1 ? _currentIndex + 1 : 0;
    if (nextIndex == _currentIndex) return;
    final song = _playList[nextIndex];
    final songKey = '${song.title}|${song.artist}';
    if (_jamendoCache.containsKey(songKey)) return;

    // Persistent cache first: reuse a previously resolved URL.
    try {
      final cached = await ResolvedUrlCache.instance.get(songKey);
      if (cached != null) {
        _rememberUrl(songKey, cached.url,
            headers: cached.headers, native: cached.native);
        return;
      }
    } catch (_) {}

    // Try Jamendo
    if (getIt.isRegistered<JamendoDataSource>()) {
      try {
        final jamendo = getIt<JamendoDataSource>();
        final results = await jamendo.search(
          '${song.title} ${song.artist}',
          limit: 1,
        ).timeout(const Duration(seconds: 5));
        if (results.isNotEmpty) {
          _rememberUrl(songKey, results.first.audioUrl);
          await ResolvedUrlCache.instance
              .put(songKey, url: results.first.audioUrl);
          return;
        }
      } catch (_) {}
    }

    // Try YouTube (native innerTube first, backend as fallback)
    if (!_jamendoCache.containsKey(songKey)) {
      try {
        final yt = await _searchYouTube(song).timeout(const Duration(seconds: 30));
        if (yt != null && yt.url.isNotEmpty) {
          final uri = Uri.tryParse(yt.url);
          print('[YT] native url host=${uri?.host} ip=${uri?.queryParameters['ip']} len=${yt.url.length}');
          for (var i = 0; i < yt.url.length; i += 400) {
            print('[YT] native chunk: ${yt.url.substring(i, i + 400 > yt.url.length ? yt.url.length : i + 400)}');
          }
          if (yt.native) {
            _resolvedVideoIds[songKey] = yt.videoId ?? '';
          }
          _rememberUrl(songKey, yt.url, headers: yt.headers, native: yt.native);
          await ResolvedUrlCache.instance
              .put(songKey, url: yt.url, headers: yt.headers, native: yt.native,
                  videoId: yt.videoId);
        }
      } catch (_) {}
    }
  }

  /// YouTube video id currently associated with the playing song, if any.
  String? _currentVideoId() {
    if (_playList.isEmpty || _currentIndex >= _playList.length) return null;
    final song = _playList[_currentIndex];
    return _resolvedVideoIds['${song.title}|${song.artist}'];
  }

  static bool _isLocalPath(String url) {
    return url.startsWith('file:') ||
        url.startsWith('/') ||
        RegExp(r'^[A-Za-z]:[\\/]').hasMatch(url);
  }

  /// Fingerprint of the audio source, used to only reuse a cached alignment
  /// measured on the exact same recording. Local files, YouTube videos (via
  /// their stable video id) and other stable URLs each get a distinct key;
  /// Deezer previews get null (never trusted / never analysed).
  static String? _fingerprintFor(String url, {String? videoId}) {
    if (url.isEmpty) return null;
    if (_isLocalPath(url)) return 'file:$url';
    if (videoId != null && videoId.isNotEmpty) return 'yt:$videoId';
    if (url.contains('dzcdn.net')) return null;
    return 'url:$url';
  }

  Future<void> _loadSyncOffset(String songId,
      {required bool forFullSong, String? sourceKey}) async {
    _analysisRequestedForSong = songId;
    try {
      final cached = await _offsetCache.getOffset(songId);
      // An offset is only trustworthy when it was measured on the exact same
      // audio source now playing; a different recording (or an unknown/legacy
      // entry) is never reused, so it can never leak into the wrong song.
      final reusable = cached != null &&
          cached.forFullSong == forFullSong &&
          sourceKey != null &&
          cached.sourceKey == sourceKey;
      if (reusable) {
        _alignment = cached.alignment;
        _emitCurrentState();
      } else {
        // No trusted alignment for the current playback source. Preview
        // offsets are meaningless for full songs and vice versa, so start
        // fresh and let the full-song analysis align it.
        _alignment = null;
        _emitCurrentState();
        if (forFullSong) _triggerAnalysis(songId);
      }
    } catch (_) {
      _alignment = null;
    }
    detectMaqam(songId, _playList[_currentIndex].urlSongsbase);
  }

  Future<void> _triggerAnalysis(String songId,
      {String? audioUrl, Map<String, String>? audioHeaders}) async {
    if (songId.isEmpty || songId != _analysisRequestedForSong) return;
    if (_analyzingSongId == songId) return;
    if (_lyricsCubit == null || _lyricsCubit!.isClosed) return;
    final lyricsState = _lyricsCubit!.state;
    if (lyricsState is! LyricsLoaded || lyricsState.lyrics.length < 3) return;

    // Lyrics fetched from innerTube for the exact video being played are
    // ground truth â€” applying a DSP-derived shift/scale would only corrupt
    // them. Use them verbatim.
    if (lyricsState.exactMatch) {
      if (_alignment != null) {
        _alignment = null;
        _emitCurrentState();
      }
      return;
    }

    // Already have a trusted alignment for this source (loaded from cache or
    // measured earlier in the session) â€” do not re-download and re-analyse.
    if (_alignment != null) return;

    // Only full-length sources are analysed: a 30s preview starts mid-song, so
    // its offset can never align lyrics with the full track. Local files
    // (offline downloads) are analysed directly from disk.
    final url = audioUrl ?? _currentPlayUrl;
    if (url.isEmpty || url.contains('dzcdn.net')) {
      return;
    }
    final headers = audioHeaders ?? _currentPlayHeaders;

    _analyzingSongId = songId;
    try {
      _analyzer ??= SyncAnalyzer(_dio);
      final alignment = await _analyzer!.analyze(url, lyricsState.lyrics,
          headers: headers);
      if (alignment != null &&
          !isClosed &&
          songId == _analysisRequestedForSong) {
        await _offsetCache.setOffset(songId, alignment,
            forFullSong: true,
            sourceKey: _fingerprintFor(url, videoId: _currentVideoId()));
        _alignment = alignment;
        _emitCurrentState();
      }
    } catch (_) {} finally {
      if (_analyzingSongId == songId) _analyzingSongId = '';
    }
  }

  Future<void> detectMaqam(String songId, String audioUrl) async {
    if (_maqamCache.containsKey(songId)) {
      _currentMaqam = _maqamCache[songId];
      _emitCurrentState();
      return;
    }
    try {
      final tempDir = await getTemporaryDirectory();
      final audioFile = File('${tempDir.path}/maqam_$songId.mp3');
      final wavFile = File('${tempDir.path}/maqam_$songId.wav');

      await _dio.download(audioUrl, audioFile.path);
      if (!audioFile.existsSync()) return;
      try {
        await _audioDecoderChannel.invokeMethod('decodeToWav', {
          'inputPath': audioFile.path,
          'outputPath': wavFile.path,
        });
      } on MissingPluginException {
        audioFile.deleteSync();
        return;
      }
      if (!wavFile.existsSync()) {
        audioFile.deleteSync();
        return;
      }

      // Heavy DSP runs off the main isolate so the UI thread never stalls.
      final wavPath = wavFile.path;
      final result = await Isolate.run<MaqamResult?>(() {
        final wavBytes = File(wavPath).readAsBytesSync();
        final sampleRate = wavSampleRate(wavBytes);
        if (sampleRate <= 0) return null;
        final samples = readWavSamples(wavBytes);
        if (samples.isEmpty) return null;
        return detectMaqamOnBackground(samples, sampleRate);
      });
      audioFile.deleteSync();
      wavFile.deleteSync();

      if (result != null && !isClosed) {
        _currentMaqam = result;
        _maqamCache[songId] = result;
        _emitCurrentState();
      }
    } catch (_) {}
  }

  void playNext() {
    final nextIndex = _currentIndex < _playList.length - 1 ? _currentIndex + 1 : 0;
    _currentIndex = nextIndex;
    loadSong(_playList, _currentIndex, _url, skipLoadingEmit: true);
  }

  Future<void> retry() async {
    if (_playList.isEmpty) return;
    if (!isClosed) emit(const SongPlayerLoading());
    await loadSong(_playList, _currentIndex, _url);
  }

  void playPrevious() {
    final prevIndex = _currentIndex > 0 ? _currentIndex - 1 : _playList.length - 1;
    _currentIndex = prevIndex;
    loadSong(_playList, _currentIndex, _url, skipLoadingEmit: true);
  }

  void seekTo(Duration? duration) {
    audioPlayer.seek(duration);
  }

  void playOrpauseSong() async {
    if (audioPlayer.playing) {
      await audioPlayer.pause();
    } else {
      await audioPlayer.play();
    }
    _emitCurrentState();
  }

  void stopAndDismiss() async {
    await audioPlayer.stop();
    _emitCurrentState();
  }

  @override
  Future<void> close() async {
    WidgetsBinding.instance.removeObserver(this);
    _listenDurationTimer?.cancel();
    _fullSongBannerTimer?.cancel();
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _youtubeNative.close();
    await audioPlayer.dispose();
    return super.close();
  }
}

class _ResolvedAudio {
  final String url;
  final Map<String, String> headers;
  final String source;

  /// True when [url] was obtained directly from the device (innerTube player
  /// API) and is signed for this device's IP â€” play it without the backend
  /// relay / readiness gate.
  final bool native;

  /// YouTube video id of the resolved track, when known (native only). Used
  /// to fetch the exact synced lyrics for the video being played.
  final String? videoId;

  const _ResolvedAudio(
    this.url,
    this.headers,
    this.source, {
    this.native = false,
    this.videoId,
  });
}

class _DioStreamAudioSource extends StreamAudioSource {
  /// googlevideo (and some CDNs) reject an open-ended range (`bytes=N-`) with
  /// an empty 403. Always bound the range end: when the player asks for an
  /// unbounded range we hand back up to this many bytes and let the source
  /// length (parsed from the Content-Range total) drive further requests.
  static const int _rangeWindow = 100 * 1024 * 1024;

  static String _boundedRangeHeader(int start, int? end) {
    if (end != null) return 'bytes=$start-${end - 1}';
    return 'bytes=$start-${start + _rangeWindow}';
  }

  final Dio _dio;
  final String _url;
  final Map<String, String>? _extraHeaders;

  _DioStreamAudioSource(this._dio, this._url, [this._extraHeaders]);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final uri = Uri.tryParse(_url);
    if (_url.isEmpty || uri == null || uri.host.isEmpty) {
      throw StateError('Invalid audio URL: $_url');
    }
    final isDeezer = _url.contains('dzcdn.net') || _url.contains('cdn-preview');
    final rangeHeader = start != null ? _boundedRangeHeader(start, end) : null;
    int? statusCode;
    String? errorMsg;
    try {
      print('[STREAM] REQ range=$rangeHeader host=${uri.host} expire=${uri.queryParameters['expire']} extraHeaders=${_extraHeaders?.length ?? 0}');
      final response = await _dio.get<ResponseBody>(
        _url,
        options: Options(
          responseType: ResponseType.stream,
          validateStatus: (_) => true,
          headers: {
            if (rangeHeader != null) 'Range': rangeHeader,
            if (isDeezer) 'Referer': 'https://www.deezer.com/',
            if (isDeezer) 'Origin': 'https://www.deezer.com',
            if (isDeezer) 'Accept': 'audio/mpeg,audio/*;q=0.9,*/*;q=0.8',
            ...?_extraHeaders,
          },
        ),
      );
      statusCode = response.statusCode;
      final contentType =
          response.headers.value('content-type') ?? 'audio/mpeg';
      final body = response.data;

      if (statusCode != null && statusCode >= 400) {
        String bodyHead = '';
        if (body != null) {
          try {
            final bytes = await body.stream
                .take(1)
                .toList()
                .timeout(const Duration(seconds: 3));
            bodyHead = bytes.isEmpty
                ? ''
                : String.fromCharCodes(bytes.first.take(400));
          } catch (_) {}
        }
        print('[STREAM] HTTP $statusCode ct=$contentType body=$bodyHead host=${Uri.tryParse(_url)?.host}');
        throw StateError('HTTP $statusCode from ${Uri.tryParse(_url)?.host}');
      }

      int? sourceLength;
      int? responseLen;
      final contentRange = response.headers.value('content-range');
      if (contentRange != null) {
        final match =
            RegExp(r'bytes\s+(\d+)-(\d+)/(\d+)').firstMatch(contentRange);
        if (match != null) {
          final endByte = int.tryParse(match.group(2)!);
          final startByte = int.tryParse(match.group(1)!);
          sourceLength = int.tryParse(match.group(3)!);
          if (endByte != null && startByte != null) {
            responseLen = endByte - startByte + 1;
          }
        }
      }
      responseLen ??=
          int.tryParse(response.headers.value('content-length') ?? '');
      responseLen ??= sourceLength ?? 0;
      sourceLength ??= responseLen;      print('[STREAM] $statusCode range=$start-${end ?? ''} ct=$contentType len=$responseLen');
      return StreamAudioResponse(
        sourceLength: sourceLength,
        contentLength: responseLen,
        stream: body?.stream ?? Stream.value(Uint8List(0)),
        offset: start ?? 0,
        contentType: contentType,
      );
    } catch (e) {
      errorMsg = '$e';
      String detail = '';
      if (e is DioException) {
        final resp = e.response;
        if (resp != null) {
          final body = resp.data;
          final bodyStr = body is String
              ? body
              : body is List<int>
                  ? String.fromCharCodes(body.take(300))
                  : body?.toString() ?? '';
          detail = ' BODY(${resp.statusCode}): ${bodyStr.length > 300 ? bodyStr.substring(0, 300) : bodyStr}';
        }
        if (e.type == DioExceptionType.badResponse && resp?.statusCode == 403) {
          detail += ' URL=${Uri.tryParse(_url)?.host}';
        }
      }
      print('[STREAM] ERROR ($statusCode): $errorMsg$detail');
      rethrow;
    }
  }
}
