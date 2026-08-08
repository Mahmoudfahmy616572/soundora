import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/data/sources/favourites/favourite_songs_data_source.dart';
import 'package:soundora/presentation/Gamification/cubit/achievement_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'favourite_songs_state.dart';

class FavouriteSongsCubit extends Cubit<FavouriteSongsState> {
  final FavouriteSongsDataSource _dataSource;
  final SupabaseClient _supabase = Supabase.instance.client;
  Set<String> _favouriteSongsIds = {};
  List<SongModel> _favouriteSongsList = [];

  FavouriteSongsCubit({FavouriteSongsDataSource? dataSource})
      : _dataSource = dataSource ?? FavouriteSongsDataSourceImpl(),
        super(FavouriteSongsInitial());

  bool isFavourite(String songId) => _favouriteSongsIds.contains(songId);

  Future<void> fetchFavourites() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    emit(FavouriteSongsLoading());
    try {
      final entries = await _dataSource.fetchFavouriteEntries(userId);
      _favouriteSongsIds = entries.map((f) => f['song_id'].toString()).toSet();
      _favouriteSongsList = entries
          .where((item) => item['songs'] != null)
          .map((item) => SongModel.fromJson(item['songs']))
          .toList();

      emit(FavouriteSongsLoaded(
          favouriteSongsIds: _favouriteSongsIds,
          favouriteSongs: _favouriteSongsList));
    } catch (e) {
      emit(FavouriteSongsFailure("Failed to load favorites: $e"));
    }
  }

  Future<void> toggleFavourite(SongModel song) async {
    final userId = _supabase.auth.currentUser?.id;
    final String songId = song.id.toString();
    if (userId == null) return;

    if (state is FavouriteSongsFailure || state is FavouriteSongsInitial) {
      emit(FavouriteSongsLoaded(favouriteSongsIds: {}, favouriteSongs: []));
    }

    if (state is! FavouriteSongsLoaded) {
      await fetchFavourites();
      if (state is! FavouriteSongsLoaded) return;
    }

    bool wasFavourite = _favouriteSongsIds.contains(songId);

    final updatedIds = Set<String>.from(_favouriteSongsIds);
    final updatedSongs = List<SongModel>.from(_favouriteSongsList);

    if (wasFavourite) {
      updatedIds.remove(songId);
      updatedSongs.removeWhere((s) => s.id.toString() == songId);
    } else {
      updatedIds.add(songId);
      updatedSongs.add(song);
    }

    _favouriteSongsIds = updatedIds;
    _favouriteSongsList = updatedSongs;

    emit(FavouriteSongsLoaded(
      favouriteSongsIds: updatedIds,
      favouriteSongs: updatedSongs,
    ));

    if (!wasFavourite) {
      try {
        GetIt.instance<AchievementCubit>().onFavouriteAdded();
      } catch (_) {}
    }

    try {
      final int? numericId = int.tryParse(songId);
      if (numericId == null) {
        return;
      }
      final songData = {
        'id': numericId,
        'title': song.title,
        'artist': song.artist,
        'urlbase': song.urlSongsbase,
        'imageUrl': song.imageUrl,
        'duration': song.duration,
        'releaseDate': song.releaseDate.toIso8601String(),
        'lyrics': song.lyrics,
      };
      if (wasFavourite) {
        await _dataSource.deleteFavourite(userId, numericId);
      } else {
        await _dataSource.insertFavourite(userId, numericId, songData);
      }
    } catch (e) {
      // Best-effort persistence: keep the optimistic local state so the
      // toggle never flickers back. The server write is retried on the
      // next fetchFavourites().
      debugPrint('toggleFavourite persistence failed for $songId: $e');
    }
  }

  Future<List<SongModel>> getFavouriteSongs() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final entries = await _dataSource.fetchFavouriteEntries(userId);
      return entries
          .where((item) => item['songs'] != null)
          .map((item) => SongModel.fromJson(item['songs']))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
