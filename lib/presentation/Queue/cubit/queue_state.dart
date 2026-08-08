import 'package:equatable/equatable.dart';
import 'package:soundora/data/models/songs/songs_model.dart';

abstract class QueueState extends Equatable {
  @override
  List<Object?> get props => [];
}

class QueueInitial extends QueueState {}

class QueueLoaded extends QueueState {
  final List<SongModel> upNext;
  final int currentPlayingIndex;

  QueueLoaded({
    required this.upNext,
    required this.currentPlayingIndex,
  });

  QueueLoaded copyWith({
    List<SongModel>? upNext,
    int? currentPlayingIndex,
  }) {
    return QueueLoaded(
      upNext: upNext ?? this.upNext,
      currentPlayingIndex: currentPlayingIndex ?? this.currentPlayingIndex,
    );
  }

  @override
  List<Object?> get props => [upNext, currentPlayingIndex];
}
