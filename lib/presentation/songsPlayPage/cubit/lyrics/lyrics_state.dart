import 'package:equatable/equatable.dart';
import 'package:soundora/data/sources/lyrics/lyrics_data_source.dart';

abstract class LyricsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LyricsInitial extends LyricsState {}

class LyricsLoading extends LyricsState {}

class LyricsLoaded extends LyricsState {
  final List<LyricLine> lyrics;
  LyricsLoaded(this.lyrics);

  /// True when the loaded lines are tied to the exact audio source being
  /// played (innerTube for the resolved video id). Their timestamps should be
  /// used verbatim, without DSP alignment.
  bool get exactMatch => lyrics.isNotEmpty && lyrics.first.exactMatch;

  // Length alone is not enough: a re-fetch with the same line count but exact
  // provenance (innerTube for the playing video) must still be delivered to
  // listeners, otherwise Cubit would skip the state as "equal".
  @override
  List<Object?> get props => [lyrics.length, exactMatch];
}

class LyricsNotFound extends LyricsState {}

class LyricsFailure extends LyricsState {
  final String errorMessage;
  LyricsFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
