import 'package:flutter_test/flutter_test.dart';
import 'package:soundora/core/services/quran_resolver.dart';
import 'package:soundora/data/models/songs/songs_model.dart';

SongModel _song(String title, String artist) => SongModel(
      id: '1',
      title: title,
      artist: artist,
      urlSongsbase: 'x.mp3',
      imageUrl: '',
      duration: '0:30',
      releaseDate: DateTime(2000),
      lyrics: '',
    );

void main() {
  group('QuranResolver.resolve', () {
    test('resolves Arabic surah title + Arabic reciter', () {
      final url = QuranResolver.resolve(
          _song('سورة الفاتحة', 'الشيخ محمد صديق المنشاوي'));
      expect(url, 'https://server10.mp3quran.net/download/minsh/001.mp3');
    });

    test('resolves with the reciter present in the title', () {
      final url = QuranResolver.resolve(_song('سورة يس المنشاوي', 'موسيقى'));
      expect(url, 'https://server10.mp3quran.net/download/minsh/036.mp3');
    });

    test('resolves English surah name', () {
      final url = QuranResolver.resolve(_song('Al-Kahf', 'الحصري'));
      expect(url, 'https://server10.mp3quran.net/download/husary/018.mp3');
    });

    test('returns null when the reciter is not supported', () {
      final url = QuranResolver.resolve(_song('سورة الفاتحة', 'موسيقى'));
      expect(url, isNull);
    });

    test('returns null for non-Quran songs', () {
      final url = QuranResolver.resolve(_song('Blinding Lights', 'The Weeknd'));
      expect(url, isNull);
    });

    test('strips diacritics from surah names', () {
      final url = QuranResolver.resolve(
          _song('سورة الفَاتِحَة', 'المنشاوي'));
      expect(url, 'https://server10.mp3quran.net/download/minsh/001.mp3');
    });
  });

  group('QuranResolver.urlFor', () {
    test('builds padded URL for a supported reciter', () {
      expect(QuranResolver.urlFor(114, 'المنشاوي'),
          'https://server10.mp3quran.net/download/minsh/114.mp3');
      expect(QuranResolver.urlFor(2, 'عبد الباسط'),
          'https://server10.mp3quran.net/download/abdulbasit/002.mp3');
    });

    test('returns null for an unsupported reciter', () {
      expect(QuranResolver.urlFor(1, 'موسيقى'), isNull);
    });
  });
}
