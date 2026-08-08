import 'package:equatable/equatable.dart';
import 'package:soundora/data/models/songs/songs_model.dart';

abstract class GetSongsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetSongsLoading extends GetSongsState {}

class GetSongsLoaded extends GetSongsState {
  final List<SongModel> songs;
  GetSongsLoaded({required this.songs});

  @override
  List<Object?> get props => [songs];
}

class GetSongsFailure extends GetSongsState {
  final String errorMessage;
  GetSongsFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
