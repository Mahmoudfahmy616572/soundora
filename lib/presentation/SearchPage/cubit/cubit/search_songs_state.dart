import 'package:equatable/equatable.dart';
import 'package:soundora/data/models/songs/songs_model.dart';

sealed class SearchSongsState extends Equatable {
  @override
  List<Object?> get props => [];
}

final class SearchSongsInitial extends SearchSongsState {}

final class SearchSongsLoading extends SearchSongsState {}

final class SearchSongsLoaded extends SearchSongsState {
  final List<SongModel> songs;
  final bool hasMore;
  SearchSongsLoaded({required this.songs, this.hasMore = false});

  @override
  List<Object?> get props => [songs, hasMore];
}

final class SearchSongsError extends SearchSongsState {
  final String errorMessage;
  SearchSongsError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
