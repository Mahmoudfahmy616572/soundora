import 'package:flutter_test/flutter_test.dart';
import 'package:soundora/core/services/quran_catalog.dart';
import 'package:soundora/presentation/Quran/cubit/quran_state.dart';

void main() {
  group('QuranCatalog', () {
    test('contains exactly 114 surahs', () {
      expect(QuranCatalog.surahs.length, 114);
    });

    test('numbered sequentially from 1 to 114', () {
      for (var i = 0; i < QuranCatalog.surahs.length; i++) {
        expect(QuranCatalog.surahs[i].number, i + 1);
      }
    });

    test('first and last surahs have correct metadata', () {
      final fatiha = QuranCatalog.byNumber(1)!;
      expect(fatiha.arabicName, 'الفاتحة');
      expect(fatiha.ayahCount, 7);
      expect(fatiha.pageStart, 1);

      final nas = QuranCatalog.byNumber(114)!;
      expect(nas.arabicName, 'الناس');
      expect(nas.ayahCount, 6);
      expect(nas.pageEnd, 604);
    });

    test('revelation labels are correct', () {
      expect(QuranCatalog.revelationLabel(2), 'مدنية');
      expect(QuranCatalog.revelationLabel(112), 'مكية');
    });

    test('pageOf maps surahs onto the 604-page mushaf', () {
      expect(QuranCatalog.pageOf(1), 1);
      expect(QuranCatalog.pageOf(18), 293);
      expect(QuranCatalog.pageOf(67), 562);
      expect(QuranCatalog.pageOf(114), 604);
    });

    test('bundled ayah counts match the declared ayahCount', () {
      const bundledNumbers = [1, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114];
      for (final n in bundledNumbers) {
        final surah = QuranCatalog.byNumber(n)!;
        expect(QuranCatalog.bundledAyahsFor(n)?.length, surah.ayahCount,
            reason: 'surah $n');
      }
    });

    test('bundled ayahs contain real Arabic text', () {
      final fatiha = QuranCatalog.bundledAyahsFor(1)!;
      expect(fatiha.first, contains('بِسْمِ'));
      final ikhlas = QuranCatalog.bundledAyahsFor(112)!;
      expect(ikhlas.first, contains('أَحَد'));
    });
  });

  group('QuranProgress', () {
    test('serializes and deserializes', () {
      final progress = QuranProgress(
        positionMs: 42000,
        durationMs: 120000,
        playCount: 3,
        lastPlayedAt: DateTime(2026, 8, 8),
        completed: false,
      );
      final restored = QuranProgress.fromJson(progress.toJson());
      expect(restored.positionMs, 42000);
      expect(restored.durationMs, 120000);
      expect(restored.playCount, 3);
      expect(restored.lastPlayedAt, DateTime(2026, 8, 8));
      expect(restored.completed, false);
    });

    test('ratio clamps to [0,1]', () {
      expect(const QuranProgress(positionMs: 60, durationMs: 120).ratio, 0.5);
      expect(const QuranProgress().ratio, 0);
    });
  });
}
