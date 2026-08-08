import 'package:equatable/equatable.dart';
import 'package:soundora/data/models/songs/songs_model.dart';

abstract class MoodMapState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MoodMapInitial extends MoodMapState {}

class MoodMapLoading extends MoodMapState {}

class MoodMapLoaded extends MoodMapState {
  final String selectedMood;
  final List<SongModel> songs;
  final Map<String, List<SongModel>> cachedMoods;

  MoodMapLoaded({
    required this.selectedMood,
    this.songs = const [],
    this.cachedMoods = const {},
  });

  MoodMapLoaded copyWith({
    String? selectedMood,
    List<SongModel>? songs,
    Map<String, List<SongModel>>? cachedMoods,
  }) {
    return MoodMapLoaded(
      selectedMood: selectedMood ?? this.selectedMood,
      songs: songs ?? this.songs,
      cachedMoods: cachedMoods ?? this.cachedMoods,
    );
  }

  @override
  List<Object?> get props => [selectedMood, songs, cachedMoods];
}

class MoodMapFailure extends MoodMapState {
  final String message;

  MoodMapFailure(this.message);

  @override
  List<Object?> get props => [message];
}
