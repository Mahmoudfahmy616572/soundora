import 'package:equatable/equatable.dart';
import 'package:soundora/data/models/songs/songs_model.dart';

enum SmartDJMode { party, chill, workout, sleep }

abstract class SmartDJState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SmartDJInitial extends SmartDJState {}

class SmartDJLoading extends SmartDJState {}

class SmartDJLoaded extends SmartDJState {
  final SmartDJMode mode;
  final List<SongModel> playlist;
  final String playlistName;

  SmartDJLoaded({
    required this.mode,
    this.playlist = const [],
    this.playlistName = '',
  });

  SmartDJLoaded copyWith({
    SmartDJMode? mode,
    List<SongModel>? playlist,
    String? playlistName,
  }) {
    return SmartDJLoaded(
      mode: mode ?? this.mode,
      playlist: playlist ?? this.playlist,
      playlistName: playlistName ?? this.playlistName,
    );
  }

  @override
  List<Object?> get props => [mode, playlist, playlistName];
}

class SmartDJFailure extends SmartDJState {
  final String message;

  SmartDJFailure(this.message);

  @override
  List<Object?> get props => [message];
}
