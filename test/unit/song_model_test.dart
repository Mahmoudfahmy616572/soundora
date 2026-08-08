import 'package:flutter_test/flutter_test.dart';
import 'package:soundora/data/models/songs/songs_model.dart';

void main() {
  group('SongModel', () {
    test('fromJson creates correct SongModel', () {
      final json = {
        'id': 1,
        'title': 'Test Song',
        'artist': 'Test Artist',
        'urlbase': 'https://example.com/song.mp3',
        'imageUrl': 'https://example.com/cover.jpg',
        'duration': '3:45',
        'releaseDate': '2024-01-15T00:00:00.000Z',
        'lyrics': 'Test lyrics',
      };

      final song = SongModel.fromJson(json);

      expect(song.id, '1');
      expect(song.title, 'Test Song');
      expect(song.artist, 'Test Artist');
      expect(song.urlSongsbase, 'https://example.com/song.mp3');
      expect(song.imageUrl, 'https://example.com/cover.jpg');
      expect(song.duration, '3:45');
      expect(song.lyrics, 'Test lyrics');
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{
        'id': 2,
        'title': null,
        'artist': null,
        'urlbase': 'url',
        'imageUrl': 'img',
        'duration': null,
        'releaseDate': '2024-01-01T00:00:00.000Z',
      };

      final song = SongModel.fromJson(json);

      expect(song.title, 'Unknown Title');
      expect(song.artist, 'Unknown Artist');
      expect(song.duration, '0:00');
    });

    test('toJson produces correct map', () {
      final song = SongModel(
        id: '3',
        title: 'My Song',
        artist: 'My Artist',
        urlSongsbase: 'url',
        imageUrl: 'img',
        duration: '2:30',
        releaseDate: DateTime(2024, 6, 15),
        lyrics: 'lyrics',
      );

      final json = song.toJson();

      expect(json['id'], '3');
      expect(json['title'], 'My Song');
      expect(json['artist'], 'My Artist');
      expect(json['duration'], '2:30');
    });

    test('roundtrip toJson/fromJson preserves data', () {
      final original = SongModel(
        id: '42',
        title: 'Roundtrip',
        artist: 'Artist',
        urlSongsbase: 'url',
        imageUrl: 'img',
        duration: '4:00',
        releaseDate: DateTime(2024, 12, 25),
        lyrics: 'roundtrip lyrics',
      );

      final restored = SongModel.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.artist, original.artist);
      expect(restored.duration, original.duration);
      expect(restored.lyrics, original.lyrics);
    });
  });
}
