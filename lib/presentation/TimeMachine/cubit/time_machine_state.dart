import 'package:equatable/equatable.dart';
import 'package:soundora/data/models/songs/songs_model.dart';

class TimeMachineState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TimeMachineInitial extends TimeMachineState {}

class TimeMachineLoading extends TimeMachineState {}

class OnThisDayLoaded extends TimeMachineState {
  final List<SongModel> songs;
  final int day;
  final int month;

  OnThisDayLoaded({
    required this.songs,
    required this.day,
    required this.month,
  });

  @override
  List<Object?> get props => [songs, day, month];
}

class DecadeLoaded extends TimeMachineState {
  final List<SongModel> songs;
  final int decade;

  DecadeLoaded({
    required this.songs,
    required this.decade,
  });

  @override
  List<Object?> get props => [songs, decade];
}

class TimeMachineFailure extends TimeMachineState {
  final String message;

  TimeMachineFailure(this.message);

  @override
  List<Object?> get props => [message];
}
