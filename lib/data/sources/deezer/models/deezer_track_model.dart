import 'package:soundora/data/models/songs/songs_model.dart';

class DeezerTrackModel {
  final int id;
  final String title;
  final String artistName;
  final String albumTitle;
  final String previewUrl;
  final String coverUrl;
  final int durationSeconds;
  final String releaseDate;

  DeezerTrackModel({
    required this.id,
    required this.title,
    required this.artistName,
    required this.albumTitle,
    required this.previewUrl,
    required this.coverUrl,
    required this.durationSeconds,
    required this.releaseDate,
  });

  factory DeezerTrackModel.fromJson(Map<String, dynamic> json) {
    final album = json['album'] as Map<String, dynamic>? ?? {};
    final artist = json['artist'] as Map<String, dynamic>? ?? {};

    return DeezerTrackModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Unknown',
      artistName: artist['name'] as String? ?? 'Unknown Artist',
      albumTitle: album['title'] as String? ?? 'Unknown Album',
      previewUrl: json['preview'] as String? ?? '',
      coverUrl: (album['cover_xl'] ?? album['cover_big'] ?? album['cover_medium'] ?? '') as String,
      durationSeconds: json['duration'] as int? ?? 0,
      releaseDate: album['release_date'] as String? ?? '',
    );
  }

  SongModel toSongModel() {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    final durationStr = '$minutes:${seconds.toString().padLeft(2, '0')}';

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(releaseDate);
    } catch (_) {
      parsedDate = DateTime(2024);
    }

    return SongModel(
      id: id.toString(),
      title: title,
      artist: artistName,
      urlSongsbase: previewUrl,
      imageUrl: coverUrl,
      duration: durationStr,
      releaseDate: parsedDate,
      lyrics: '',
    );
  }

  static List<SongModel> toSongModelList(List<DeezerTrackModel> tracks) {
    return tracks.map((t) => t.toSongModel()).toList();
  }
}
