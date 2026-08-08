import 'package:flutter_test/flutter_test.dart';
import 'package:soundora/data/sources/lyrics/lyrics_data_source.dart';

void main() {
  group('LyricLine', () {
    test('defaults exactMatch to false', () {
      final line = LyricLine('Hello', const Duration(seconds: 2));
      expect(line.exactMatch, isFalse);
    });

    test('toJson/fromJson round-trips exactMatch', () {
      final exact = LyricLine('A', const Duration(milliseconds: 1500),
          exactMatch: true);
      final restored = LyricLine.fromJson(exact.toJson());
      expect(restored.text, 'A');
      expect(restored.startTime, const Duration(milliseconds: 1500));
      expect(restored.exactMatch, isTrue);
    });

    test('fromJson treats missing exact flag as false', () {
      final line = LyricLine.fromJson({'text': 'B', 'ms': 500});
      expect(line.exactMatch, isFalse);
    });
  });
}
