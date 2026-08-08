import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import '../../../core/services/quran_catalog.dart';

abstract class QuranTextDataSource {
  /// Returns the ayah texts (Uthmani script) of [surahNumber] in order.
  ///
  /// Resolution order: bundled catalog -> Hive cache -> alquran.cloud API.
  /// Bundled ayahs and cached copies are returned synchronously-ish; network
  /// failures fall back to the bundled text when available.
  Future<List<String>> fetchAyahs(int surahNumber);

  /// Saves the ayah list for [surahNumber] to the local cache.
  Future<void> cacheAyahs(int surahNumber, List<String> ayahs);
}

class QuranTextDataSourceImpl implements QuranTextDataSource {
  static const String _boxName = 'quran_ayahs';
  static const String _apiBase = 'https://api.alquran.cloud/v1/surah';

  final Dio _dio;

  QuranTextDataSourceImpl({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              headers: {'Accept': 'application/json'},
            ));

  @override
  Future<List<String>> fetchAyahs(int surahNumber) async {
    final bundled = QuranCatalog.bundledAyahsFor(surahNumber);
    if (bundled != null) return bundled;

    final cached = await _readCache(surahNumber);
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final response = await _dio.get('$_apiBase/$surahNumber/quran-uthmani');
      final data = response.data as Map<String, dynamic>;
      final ayahsJson = data['data']?['ayahs'] as List<dynamic>?;
      if (ayahsJson == null) return bundled ?? const [];
      final ayahs = ayahsJson
          .map((e) => ((e as Map<String, dynamic>)['text'] as String?) ?? '')
          .where((t) => t.isNotEmpty)
          .toList();
      if (ayahs.isNotEmpty) await cacheAyahs(surahNumber, ayahs);
      return ayahs;
    } catch (_) {
      return bundled ?? const [];
    }
  }

  @override
  Future<void> cacheAyahs(int surahNumber, List<String> ayahs) async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(
          surahNumber.toString(), jsonEncode(ayahs));
    } catch (_) {
      // Cache is best-effort; never block reading.
    }
  }

  Future<List<String>?> _readCache(int surahNumber) async {
    try {
      final box = await Hive.openBox(_boxName);
      final raw = box.get(surahNumber.toString()) as String?;
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return null;
    }
  }
}
