import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/data/models/taste_profile/taste_profile.dart';
import 'package:soundora/data/sources/listening_history/listening_data_source.dart';
import 'package:soundora/data/sources/lastfm/lastfm_data_source.dart';
import 'package:soundora/presentation/TasteProfile/cubit/taste_profile_cubit.dart';
import 'package:soundora/serviece_locator.dart';

part 'smart_queue_state.dart';

class SmartQueueCubit extends Cubit<SmartQueueState> {
  final TasteProfileCubit _tasteProfileCubit;

  SmartQueueCubit({
    required TasteProfileCubit tasteProfileCubit,
    ListeningDataSource? listeningDataSource,
  })  : _tasteProfileCubit = tasteProfileCubit,
        super(SmartQueueInitial());

  Future<List<SongModel>> suggestNextSongs({
    required SongModel currentSong,
    required List<SongModel> currentQueue,
    int count = 5,
  }) async {
    final profile = _tasteProfileCubit.currentProfile;
    if (profile == null || profile.topGenres.isEmpty) {
      return [];
    }

    try {
      final lastFm = getIt<LastFmDataSource>();
      final similar = await lastFm.getSimilarTracks(
        currentSong.artist,
        currentSong.title,
        limit: 20,
      );

      if (similar.isEmpty) return [];

      final queueIds = currentQueue.map((s) => s.id).toSet();
      final suggestions = <SongModel>[];

      for (final track in similar) {
        if (suggestions.length >= count) break;
        if (queueIds.contains(track.name)) continue;

        suggestions.add(SongModel(
          id: track.name.hashCode.toString(),
          title: track.name,
          artist: track.artist,
          urlSongsbase: '',
          imageUrl: track.imageUrl ?? '',
          duration: '0:00',
          releaseDate: DateTime(2000),
          lyrics: '',
        ));
      }

      return _rankByTaste(suggestions, profile).take(count).toList();
    } catch (_) {
      return [];
    }
  }

  List<SongModel> _rankByTaste(List<SongModel> songs, TasteProfile profile) {
    final scored = songs.map((song) {
      double score = 0;

      final artistIdx = profile.topArtists.indexOf(song.artist);
      if (artistIdx >= 0) {
        score += (10 - artistIdx).toDouble();
      }

      return MapEntry(song, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }
}
