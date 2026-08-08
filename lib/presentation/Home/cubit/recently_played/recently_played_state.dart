import 'package:equatable/equatable.dart';
import 'package:soundora/data/models/songs/songs_model.dart';

abstract class RecentlyPlayedState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RecentlyPlayedInitial extends RecentlyPlayedState {}

class RecentlyPlayedLoading extends RecentlyPlayedState {}

class RecentlyPlayedLoaded extends RecentlyPlayedState {
  final List<SongModel> songs;

  RecentlyPlayedLoaded(this.songs);

  @override
  List<Object?> get props => [songs.map((s) => s.id).toList()];
}
