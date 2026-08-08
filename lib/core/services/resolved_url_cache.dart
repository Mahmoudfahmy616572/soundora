import 'package:hive/hive.dart';

class CachedResolvedUrl {
  const CachedResolvedUrl({
    required this.url,
    required this.headers,
    this.native = false,
    this.videoId,
  });

  final String url;
  final Map<String, String> headers;

  /// True when the URL was obtained directly from the device (innerTube
  /// player API) and is signed for this device's IP — it plays without the
  /// backend relay. False for backend-relayed googlevideo URLs.
  final bool native;

  /// YouTube video id of the resolved track, when known (native only). Used
  /// to fetch the exact synced lyrics (innerTube) for the video actually
  /// playing, and to fingerprint the audio source for alignment caching.
  final String? videoId;
}

/// Persistent cache of resolved full-song URLs (title|artist -> url + headers).
///
/// YouTube googlevideo URLs are IP-locked and expire (the `expire=` param is
/// ~6h), so entries from YouTube are only reused for a short window. All other
/// URLs are reused for [_globalTtl] before being dropped. The box is capped at
/// [_maxEntries] and pruned at startup via [purgeExpired].
class ResolvedUrlCache {
  ResolvedUrlCache._();

  static final ResolvedUrlCache instance = ResolvedUrlCache._();

  static const _boxName = 'resolved_urls';
  static const _maxEntries = 150;
  static const _ytUrlTtl = Duration(hours: 2);
  static const _globalTtl = Duration(days: 30);

  Box? _box;

  Future<Box> _getBox() async {
    if (_box != null) return _box!;
    _box = await Hive.openBox(_boxName);
    return _box!;
  }

  Future<void> put(
    String key, {
    required String url,
    Map<String, String> headers = const {},
    bool native = false,
    String? videoId,
  }) async {
    if (url.isEmpty || url.contains('dzcdn.net')) return;
    final box = await _getBox();
    await box.put(key, {
      'url': url,
      'headers': headers,
      'native': native,
      'videoId': videoId,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
    while (box.length > _maxEntries) {
      String? oldestKey;
      int? oldestTs;
      box.toMap().forEach((k, v) {
        final ts = ((v as Map?)?['ts'] as int?) ?? 0;
        if (oldestTs == null || ts < oldestTs!) {
          oldestTs = ts;
          oldestKey = k as String;
        }
      });
      if (oldestKey != null) {
        await box.delete(oldestKey);
      } else {
        break;
      }
    }
  }

  bool _isExpired(Map<dynamic, dynamic> raw) {
    final ts = (raw['ts'] as int?) ?? 0;
    final url = (raw['url'] as String?) ?? '';
    final now = DateTime.now().millisecondsSinceEpoch;
    if (url.contains('googlevideo.com')) {
      return now - ts > _ytUrlTtl.inMilliseconds;
    }
    return now - ts > _globalTtl.inMilliseconds;
  }

  Future<CachedResolvedUrl?> get(String key) async {
    final box = await _getBox();
    final raw = box.get(key);
    if (raw == null) return null;
    final url = (raw as Map)['url'] as String?;
    if (url == null || url.isEmpty || url.contains('dzcdn.net')) {
      await box.delete(key);
      return null;
    }
    if (_isExpired(raw)) {
      await box.delete(key);
      return null;
    }
    if (_urlExpired(url)) {
      await box.delete(key);
      return null;
    }
    final headers = <String, String>{};
    ((raw['headers'] as Map?) ?? {}).forEach((k, v) {
      if (v is String) headers[k.toString()] = v;
    });
    return CachedResolvedUrl(
      url: url,
      headers: headers,
      native: raw['native'] == true,
      videoId: raw['videoId'] as String?,
    );
  }

  /// Removes a single entry (e.g. when its URL can no longer be played).
  Future<void> remove(String key) async {
    try {
      final box = await _getBox();
      await box.delete(key);
    } catch (_) {}
  }

  /// True when the URL carries an `expire=` param that has already passed
  /// (googlevideo URLs always include it).
  static bool _urlExpired(String url) {
    try {
      final uri = Uri.parse(url);
      final expire = uri.queryParameters['expire'];
      if (expire == null) return false;
      final exp = int.tryParse(expire);
      if (exp == null) return false;
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return exp <= nowSec + 300;
    } catch (_) {
      return false;
    }
  }

  /// Removes expired and invalid entries. Called once at app startup.
  Future<void> purgeExpired() async {
    try {
      final box = await _getBox();
      final expired = <dynamic>[];
      box.toMap().forEach((k, v) {
        final raw = v as Map?;
        final url = (raw?['url'] as String?) ?? '';
        if (url.isEmpty ||
            url.contains('dzcdn.net') ||
            _isExpired(raw ?? {}) ||
            _urlExpired(url)) {
          expired.add(k);
        }
      });
      if (expired.isNotEmpty) {
        await box.deleteAll(expired);
      }
    } catch (_) {}
  }
}
