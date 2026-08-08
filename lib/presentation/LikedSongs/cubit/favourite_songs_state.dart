import 'package:equatable/equatable.dart';
import 'package:soundora/data/models/songs/songs_model.dart';

abstract class FavouriteSongsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FavouriteSongsInitial extends FavouriteSongsState {}

class FavouriteSongsLoading extends FavouriteSongsState {}

class FavouriteSongsLoaded extends FavouriteSongsState {
  final Set<String> favouriteSongsIds;
  final List<SongModel> favouriteSongs;
  FavouriteSongsLoaded(
      {required this.favouriteSongsIds, required this.favouriteSongs});

  @override
  List<Object?> get props => [favouriteSongsIds, favouriteSongs];
}

class FavouriteSongsFailure extends FavouriteSongsState {
  final String errorMessage;
  FavouriteSongsFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
