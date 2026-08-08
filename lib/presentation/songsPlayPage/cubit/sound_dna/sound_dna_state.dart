import 'package:equatable/equatable.dart';
import 'package:soundora/data/sources/music_iwant/models/music_iwant_song_model.dart';

abstract class SoundDnaState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SoundDnaInitial extends SoundDnaState {}

class SoundDnaLoading extends SoundDnaState {}

class SoundDnaLoaded extends SoundDnaState {
  final MusicIWantSongModel songFeatures;
  SoundDnaLoaded(this.songFeatures);

  @override
  List<Object?> get props => [songFeatures.title, songFeatures.artist];
}

class SoundDnaNotFound extends SoundDnaState {}

class SoundDnaError extends SoundDnaState {
  final String errorMessage;
  SoundDnaError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
