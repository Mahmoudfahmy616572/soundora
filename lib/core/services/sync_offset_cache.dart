import 'package:hive/hive.dart';
import 'package:soundora/core/services/lyric_alignment.dart';

class CachedSyncOffset {
  final LyricAlignment alignment;
  final bool forFullSong;
  final bool manual;

  /// Fingerprint of the audio source the offset was measured against
  /// (e.g. `yt:<videoId>`, `url:<stableUrl>`, `file:<path>`). An offset is
  /// only reusable when it matches the currently playing source; a different
  /// recording needs a fresh measurement. Null for legacy entries, which are
  /// therefore never trusted.
  final String? sourceKey;

  const CachedSyncOffset(this.alignment,
      {required this.forFullSong, this.manual = false, this.sourceKey});
}

class SyncOffsetCache {
  static const _boxName = 'sync_offsets';
  static const _ttl = Duration(days: 90);
  static const _maxEntries = 200;

  /// Alignment algorithm version. Bumped whenever the analyser changes so
  /// offsets measured with an older (now known to be imprecise) method are
  /// discarded and re-measured instead of silently reusing drift.
  static const int _schemaVersion = 2;

  Future<Box> _getBox() => Hive.openBox(_boxName);

  Future<CachedSyncOffset?> getOffset(String songId) async {
    final box = await _getBox();
    final raw = box.get(songId);
    if (raw == null) return null;

    final double shiftMs;
    final double scale;
    final bool forFullSong;
    final bool manual;
    final String? sourceKey;
    if (raw is Map) {
      final ts = (raw['ts'] as int?) ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - ts > _ttl.inMilliseconds) {
        await box.delete(songId);
        return null;
      }
      shiftMs = ((raw['ms'] as num?)?.toDouble() ?? 0);
      scale = (raw['scale'] as num?)?.toDouble() ?? 1.0;
      manual = (raw['manual'] as bool?) ?? false;
      sourceKey = raw['src'] as String?;
      // Offsets measured on the 30s preview were only valid for that preview.
      // Legacy plain-int entries predate provenance and are treated as preview
      // offsets so they never leak into full-song playback.
      forFullSong = (raw['source'] as String?) == 'full';
      // Full-song entries written before the shift+scale alignment existed
      // came from the broken constant-offset analyser. Invalidate them so a
      // fresh alignment runs instead of reusing garbage.
      if (forFullSong && !raw.containsKey('scale')) {
        await box.delete(songId);
        return null;
      }
      // Entries measured with an older alignment algorithm are stale (the
      // anchor was wrong per-song, causing lyrics to lag or race). Only manual
      // user tweaks survive a schema change.
      if ((raw['ver'] as int?) != _schemaVersion && !manual) {
        await box.delete(songId);
        return null;
      }
    } else {
      shiftMs = (raw as num).toDouble();
      scale = 1.0;
      manual = false;
      forFullSong = false;
      sourceKey = null;
    }
    if (shiftMs == 0 && scale == 1.0) {
      await box.delete(songId);
      return null;
    }
    return CachedSyncOffset(
      LyricAlignment(shiftMs: shiftMs, scale: scale),
      forFullSong: forFullSong,
      manual: manual,
      sourceKey: sourceKey,
    );
  }

  /// True when a trusted full-song offset is cached (and not expired).
  Future<bool> hasFullOffset(String songId) async {
    try {
      final cached = await getOffset(songId);
      return cached != null && cached.forFullSong;
    } catch (_) {
      return false;
    }
  }

  Future<void> setOffset(String songId, LyricAlignment alignment,
      {required bool forFullSong,
      bool manual = false,
      String? sourceKey}) async {
    final box = await _getBox();
    await box.put(songId, {
      'ms': alignment.shiftMs,
      'scale': alignment.scale,
      'manual': manual,
      'ts': DateTime.now().millisecondsSinceEpoch,
      'source': forFullSong ? 'full' : 'preview',
      'src': sourceKey,
      'ver': _schemaVersion,
    });
    if (box.length > _maxEntries) {
      await purge();
    }
  }

  Future<bool> hasOffset(String songId) async {
    final box = await _getBox();
    return box.containsKey(songId);
  }

  /// Removes expired/stale entries. Called at app startup.
  Future<void> purge() async {
    try {
      final box = await _getBox();
      final now = DateTime.now().millisecondsSinceEpoch;
      final expired = <dynamic>[];
      box.toMap().forEach((k, v) {
        if (v is Map) {
          final ts = (v['ts'] as int?) ?? 0;
          if (now - ts > _ttl.inMilliseconds) expired.add(k);
        }
      });
      if (expired.isNotEmpty) await box.deleteAll(expired);

      if (box.length > _maxEntries) {
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
        for (var i = 0; i < entries.length - _maxEntries; i++) {
          await box.delete(entries[i].key);
        }
      }
    } catch (_) {}
  }
}
