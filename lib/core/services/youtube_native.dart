// ignore_for_file: avoid_print
import 'package:dio/dio.dart';

/// A full-track YouTube audio URL obtained directly from the device via
/// YouTube's innerTube player API (the same approach NewPipe/ViMusic use).
///
/// The resulting googlevideo URL is signed for the requesting IP, so it is
/// only playable from this device (or a device sharing its egress, e.g. the
/// Android emulator on the same machine). No backend, cookies or account are
/// involved.
class YtNativeTrack {
  const YtNativeTrack({
    required this.url,
    required this.headers,
    required this.title,
    this.videoId,
  });

  final String url;
  final Map<String, String> headers;
  final String title;

  /// The YouTube video id this audio came from. Used to fetch the exact
  /// synced lyrics for the playing video (innerTube) instead of guessing
  /// by title/artist text.
  final String? videoId;
}

/// Resolves YouTube full audio straight from the device, bypassing the
/// backend entirely. The android client works anonymously from home/residential
/// IPs (unlike datacenter IPs which get bot-checked).
class YoutubeNative {
  static const String _clientName = 'ANDROID';
  static const String _clientVersion = '20.11.39';
  static const String _ua =
      'com.google.android.youtube/$_clientVersion (Linux; U; Android 13) gzip';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 40),
  ));

  /// POSTs to an innerTube endpoint and returns the decoded JSON body.
  Future<Map<String, dynamic>> _innerTube(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      'https://www.youtube.com/youtubei/v1/$endpoint?prettyPrint=false',
      data: {
        'context': {
          'client': {
            'clientName': _clientName,
            'clientVersion': _clientVersion,
            'hl': 'en',
            'gl': 'US',
          },
        },
        ...body,
      },
      options: Options(
        responseType: ResponseType.json,
        headers: {
          'User-Agent': _ua,
          'X-Youtube-Client-Name': '3',
          'X-Youtube-Client-Version': _clientVersion,
          'Origin': 'https://www.youtube.com',
        },
      ),
    );
    return resp.data ?? {};
  }

  /// Deep-first search for the first search-result video that has an id.
  Map<String, dynamic>? _firstSearchVideo(dynamic node) {
    if (node is List) {
      for (final item in node) {
        final found = _firstSearchVideo(item);
        if (found != null) return found;
      }
      return null;
    }
    if (node is Map) {
      for (final key in ['videoRenderer', 'compactVideoRenderer']) {
        final video = node[key];
        if (video is Map) {
          final id = video['videoId'];
          if (id is String && id.isNotEmpty) {
            return Map<String, dynamic>.from(video);
          }
        }
      }
      for (final value in node.values) {
        final found = _firstSearchVideo(value);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Searches YouTube and returns the first playable video id.
  Future<String?> searchVideoId(String query) async {
    final data = await _innerTube('search', {'query': query});
    final video = _firstSearchVideo(data);
    final id = video == null ? null : video['videoId'] as String?;
    print('[YT] search videoId: $id');
    return id;
  }

  /// Resolves the best audio stream URL for a known video id.
  Future<YtNativeTrack?> audioFromVideo(String videoId) async {
    final data = await _innerTube('player', {
      'videoId': videoId,
      'contentCheckOk': true,
      'racyCheckOk': true,
    });

    final playability = data['playabilityStatus'];
    final status = playability is Map ? playability['status'] : null;
    print('[YT] player status: $status');
    if (playability is! Map || status != 'OK') return null;

    final videoDetails = data['videoDetails'];
    final title = videoDetails is Map
        ? (videoDetails['title'] as String? ?? '')
        : '';

    final streaming = data['streamingData'];
    if (streaming is! Map) return null;

    final formats = <Map<String, dynamic>>[];
    for (final key in ['formats', 'adaptiveFormats']) {
      final list = streaming[key];
      if (list is List) {
        for (final fmt in list) {
          if (fmt is Map) formats.add(Map<String, dynamic>.from(fmt));
        }
      }
    }

    // YouTube's CDN only lets anonymous (pot-less) clients stream the FIRST
    // ~1MB of adaptive audio-only streams (itag 140/251...); any larger or
    // mid-file range returns an empty 403. The muxed A/V formats (itag 18 =
    // 360p mp4) are NOT gated and stream the whole file on any range, so we
    // prefer those and only fall back to adaptive audio when none exists.
    final candidates = formats.where((fmt) {
      final mime = fmt['mimeType'] as String? ?? '';
      final url = fmt['url'];
      return mime.isNotEmpty && url is String && url.isNotEmpty;
    }).toList();

    Map<String, dynamic>? best;
    final muxed = candidates
        .where((fmt) => (fmt['mimeType'] as String).startsWith('video/'))
        .toList();
    if (muxed.isNotEmpty) {
      for (final fmt in muxed) {
        if (fmt['itag'] == 18) {
          best = fmt;
          break;
        }
      }
      best ??= muxed.first;
    }
    if (best == null) {
      for (final fmt in candidates) {
        final mime = fmt['mimeType'] as String? ?? '';
        final url = fmt['url'];
        if (!mime.startsWith('audio/') || url is! String || url.isEmpty) {
          continue;
        }
        final quality = fmt['audioQuality'] as String? ?? '';
        final bitrate = int.tryParse('${fmt['bitrate']}') ?? 0;
        if (best == null ||
            (quality == 'AUDIO_QUALITY_MEDIUM' &&
                best['audioQuality'] != 'AUDIO_QUALITY_MEDIUM') ||
            (quality == best['audioQuality'] &&
                bitrate > (int.tryParse('${best['bitrate']}') ?? 0))) {
          best = fmt;
        }
      }
    }

    if (best == null) return null;

    final itag = best['itag'];
    final mimeSel = best['mimeType'];
    print('[YT] stream: itag=$itag mime=$mimeSel');

    return YtNativeTrack(
      url: best['url'] as String,
      headers: const {'User-Agent': _ua},
      title: title,
      videoId: videoId,
    );
  }

  /// One-shot: search + player API, returns the best full-track audio.
  Future<YtNativeTrack?> resolveBestAudio(String query) async {
    final videoId = await searchVideoId(query);
    if (videoId == null) return null;
    return audioFromVideo(videoId);
  }

  void close() => _dio.close(force: true);
}
