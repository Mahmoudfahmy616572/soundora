import 'package:equatable/equatable.dart';
import 'package:soundora/data/sources/models/combined_artist_model.dart';

abstract class ArtistDetailsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ArtistDetailsInitial extends ArtistDetailsState {}

class ArtistDetailsLoading extends ArtistDetailsState {}

class ArtistDetailsLoaded extends ArtistDetailsState {
  final CombinedArtistModel artist;
  ArtistDetailsLoaded({required this.artist});

  @override
  List<Object?> get props => [artist];
}

class ArtistDetailsError extends ArtistDetailsState {
  final String errorMessage;
  ArtistDetailsError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
