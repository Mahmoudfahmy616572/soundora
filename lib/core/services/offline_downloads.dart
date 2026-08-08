import 'dart:io';

import 'package:hive/hive.dart';

/// Manages the offline song store (files + the `offline_songs` Hive box).
///
/// Entries live at most [ttl] (30 days), mirroring YouTube's download expiry.
/// After that, [sweepExpired] deletes the file while the Hive entry stays so
/// the downloads page can show an "expired" state and offer a re-download.
class OfflineDownloads {
  OfflineDownloads._();

  static const String boxName = 'offline_songs';
  static const Duration ttl = Duration(days: 30);

  static Map<String, dynamic>? _entry(String songId) {
    final raw = Hive.box(boxName).get(songId);
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    // Legacy entry: plain file path (pre-TTL downloads).
    if (raw is String) {
      return {
        'path': raw,
        'downloadedAt': DateTime.now().millisecondsSinceEpoch,
      };
    }
    return null;
  }

  static bool _isExpired(Map<String, dynamic> entry) {
    final ts = entry['downloadedAt'];
    if (ts is! int) return false;
    return DateTime.now().millisecondsSinceEpoch - ts > ttl.inMilliseconds;
  }

  /// Path of a valid, non-expired download for [songId], or null when the
  /// download is missing, expired, or its file no longer exists on disk.
  static Future<String?> pathOf(String songId) async {
    try {
      final entry = _entry(songId);
      if (entry == null) return null;
      final path = entry['path'] as String? ?? '';
      if (path.isEmpty || _isExpired(entry)) return null;
      if (!await File(path).exists()) return null;
      return path;
    } catch (_) {
      return null;
    }
  }

  /// Synchronous variant of [pathOf] for widget builders.
  static String? syncPathOf(String songId) {
    try {
      final entry = _entry(songId);
      if (entry == null) return null;
      final path = entry['path'] as String? ?? '';
      if (path.isEmpty || _isExpired(entry)) return null;
      if (!File(path).existsSync()) return null;
      return path;
    } catch (_) {
      return null;
    }
  }

  /// True when the entry exists but its file is gone or its TTL passed.
  static bool isExpiredEntry(String songId) {
    try {
      final entry = _entry(songId);
      if (entry == null) return false;
      final path = entry['path'] as String? ?? '';
      return _isExpired(entry) || (path.isNotEmpty && !File(path).existsSync());
    } catch (_) {
      return false;
    }
  }

  /// Remaining full days before [songId] expires (0 when expired).
  static int? remainingDays(String songId) {
    try {
      final entry = _entry(songId);
      if (entry == null) return null;
      final ts = entry['downloadedAt'];
      if (ts is! int) return null;
      final remaining = ttl.inMilliseconds -
          (DateTime.now().millisecondsSinceEpoch - ts);
      if (remaining <= 0) return 0;
      return (remaining / Duration.millisecondsPerDay).ceil();
    } catch (_) {
      return null;
    }
  }

  static Future<void> register(String songId, String path) async {
    final box = Hive.box(boxName);
    await box.put(songId, {
      'path': path,
      'downloadedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<void> remove(String songId) async {
    final entry = _entry(songId);
    final path = entry?['path'] as String? ?? '';
    if (path.isNotEmpty) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    await Hive.box(boxName).delete(songId);
  }

  /// Deletes expired files. The Hive entries stay so the downloads page can
  /// offer a re-download. Called once at app startup.
  static Future<void> sweepExpired() async {
    try {
      final box = Hive.box(boxName);
      for (final key in box.keys.toList()) {
        final entry = _entry(key as String);
        if (entry == null || !_isExpired(entry)) continue;
        final path = entry['path'] as String? ?? '';
        if (path.isNotEmpty) {
          try {
            final f = File(path);
            if (await f.exists()) await f.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
