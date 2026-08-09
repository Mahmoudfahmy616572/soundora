import 'package:equatable/equatable.dart';
import 'package:soundora/data/models/songs/songs_model.dart';

abstract class EditorialPicksState extends Equatable {
  @override
  List<Object?> get props => [];
}

class EditorialPicksLoading extends EditorialPicksState {}

class EditorialPicksLoaded extends EditorialPicksState {
  final List<SongModel> songs;
  EditorialPicksLoaded({required this.songs});

  @override
  List<Object?> get props => [songs];
}

class EditorialPicksFailure extends EditorialPicksState {
  final String errorMessage;
  EditorialPicksFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
