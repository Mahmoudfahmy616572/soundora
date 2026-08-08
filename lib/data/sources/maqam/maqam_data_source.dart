import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/songs/songs_model.dart';

abstract class MaqamDataSource {
  /// Groups all songs tagged with a maqam (canonical English key, e.g. 'Rast').
  Future<Map<String, List<SongModel>>> getSongsGroupedByMaqam();

  /// Returns the songs tagged with [maqam].
  Future<List<SongModel>> getSongsByMaqam(String maqam);
}

class MaqamDataSourceImpl implements MaqamDataSource {
  @override
  Future<Map<String, List<SongModel>>> getSongsGroupedByMaqam() async {
    final rows = await _fetchAssignments();
    final grouped = <String, List<SongModel>>{};
    for (final row in rows) {
      final maqam = (row['maqam'] as String?) ?? '';
      final songJson = row['Songs'] as Map<String, dynamic>?;
      if (maqam.isEmpty || songJson == null) continue;
      final song = _toSongModel(songJson);
      grouped.putIfAbsent(maqam, () => []).add(song);
    }
    return grouped;
  }

  @override
  Future<List<SongModel>> getSongsByMaqam(String maqam) async {
    final rows = await _fetchAssignments();
    return rows
        .where((row) => (row['maqam'] as String?) == maqam)
        .map((row) => _toSongModel(row['Songs'] as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchAssignments() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('song_maqams')
        .select('*, Songs(*)')
        .order('song_id', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  SongModel _toSongModel(Map<String, dynamic> json) {
    final supabase = Supabase.instance.client;
    final song = SongModel.fromJson(json);

    final String publicSongsUrl;
    if (song.urlSongsbase.startsWith('http')) {
      publicSongsUrl = song.urlSongsbase;
    } else {
      publicSongsUrl =
          supabase.storage.from('songs').getPublicUrl(song.urlSongsbase);
    }

    final String publicImageUrl;
    if (song.imageUrl.startsWith('http')) {
      publicImageUrl = song.imageUrl;
    } else {
      publicImageUrl =
          supabase.storage.from('covers').getPublicUrl(song.imageUrl);
    }

    return SongModel(
      id: song.id,
      title: song.title,
      artist: song.artist,
      urlSongsbase: publicSongsUrl,
      imageUrl: publicImageUrl,
      duration: song.duration,
      releaseDate: song.releaseDate,
      lyrics: song.lyrics,
    );
  }
}
