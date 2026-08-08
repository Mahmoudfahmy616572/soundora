import 'package:equatable/equatable.dart';
import 'package:soundora/presentation/LyricsMemory/models/lyrics_memory_model.dart';

abstract class LyricsMemoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LyricsMemoryInitial extends LyricsMemoryState {}

class LyricsMemoryLoading extends LyricsMemoryState {}

class LyricsMemoryLoaded extends LyricsMemoryState {
  final List<LyricsMemoryEntry> allEntries;
  final List<LyricsMemoryEntry> forgottenSongs;
  final List<LyricsMemoryEntry> recentSongs;
  final List<LyricsMemoryEntry> onThisDaySongs;
  final LyricsMemoryStats stats;

  LyricsMemoryLoaded({
    required this.allEntries,
    required this.forgottenSongs,
    required this.recentSongs,
    required this.onThisDaySongs,
    required this.stats,
  });

  @override
  List<Object?> get props =>
      [allEntries.length, forgottenSongs.length, recentSongs.length];
}
