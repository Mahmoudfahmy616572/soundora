import 'package:equatable/equatable.dart';
import 'package:soundora/data/models/songs/songs_model.dart';

class MaqamState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MaqamInitial extends MaqamState {}

class MaqamLoading extends MaqamState {}

class MaqamLoaded extends MaqamState {
  final Map<String, List<SongModel>> songsByMaqam;

  MaqamLoaded({required this.songsByMaqam});

  @override
  List<Object?> get props => [songsByMaqam];
}

class MaqamFailure extends MaqamState {
  final String message;

  MaqamFailure(this.message);

  @override
  List<Object?> get props => [message];
}
