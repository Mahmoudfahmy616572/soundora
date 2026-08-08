import 'package:flutter_test/flutter_test.dart';
import 'package:soundora/core/services/maqam_detector.dart';
import 'package:soundora/presentation/Maqam/maqam_catalog.dart';

void main() {
  group('MaqamInfo catalog', () {
    test('contains the eight supported maqamat', () {
      expect(MaqamInfo.all.length, 8);
    });

    test('all keys are unique and non-empty', () {
      final keys = MaqamInfo.all.map((m) => m.key).toSet();
      expect(keys.length, MaqamInfo.all.length);
      for (final info in MaqamInfo.all) {
        expect(info.key, isNotEmpty);
        expect(info.arabicName, isNotEmpty);
        expect(info.englishName, isNotEmpty);
      }
    });

    test('byKey resolves canonical and localized names', () {
      expect(MaqamInfo.byKey('Rast')?.arabicName, 'راست');
      expect(MaqamInfo.byKey('راست')?.key, 'Rast');
      expect(MaqamInfo.byKey('Hijaz')?.arabicName, 'حجاز');
      expect(MaqamInfo.byKey('غير موجود'), isNull);
      expect(MaqamInfo.byKey(null), isNull);
    });

    test('byKey covers every detector template', () {
      const templateKeys = {
        'Rast', 'Nahawand', 'Ajam', 'Hijaz',
        'Saba', 'Kurd', 'Sikah', 'Bayati',
      };
      for (final key in templateKeys) {
        expect(MaqamInfo.byKey(key), isNotNull, reason: 'missing $key');
      }
    });

    test('fromResult maps a detector result to its catalog entry', () {
      final result = MaqamResult(
        arabicName: 'حجاز',
        englishName: 'Hijaz',
        tonicName: 'D',
        confidence: 0.87,
      );
      final info = MaqamInfo.fromResult(result);
      expect(info, isNotNull);
      expect(info!.key, 'Hijaz');
      expect(info.arabicName, 'حجاز');
    });
  });
}
