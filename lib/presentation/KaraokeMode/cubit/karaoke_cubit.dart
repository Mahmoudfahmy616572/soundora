import 'package:bloc/bloc.dart';
import 'package:soundora/core/services/lyric_alignment.dart';
import 'package:soundora/data/sources/lyrics/lyrics_data_source.dart';

part 'karaoke_state.dart';

class KaraokeCubit extends Cubit<KaraokeState> {
  List<LyricLine> _lyrics = [];
  int _currentLineIndex = -1;
  int _tappedCorrectly = 0;
  int _totalTaps = 0;
  bool _isRecording = false;
  LyricAlignment? _alignment;

  KaraokeCubit() : super(const KaraokeInitial());

  void setLyrics(List<LyricLine> lyrics) {
    _lyrics = lyrics;
  }

  void setAlignment(LyricAlignment? alignment) {
    _alignment = alignment;
  }

  Duration _effectiveTime(LyricLine line) {
    final a = _alignment;
    return a != null ? a.effectiveTime(line.startTime) : line.startTime;
  }

  void updateCurrentLine(int index) {
    if (index >= 0 && index < _lyrics.length && index != _currentLineIndex) {
      _currentLineIndex = index;
    }
  }

  void startSession() {
    _tappedCorrectly = 0;
    _totalTaps = 0;
    _isRecording = true;
    _currentLineIndex = -1;
    emit(const KaraokeRecording(score: 0, linesCompleted: 0));
  }

  void stopSession() {
    _isRecording = false;
    final score = _totalTaps > 0
        ? ((_tappedCorrectly / _totalTaps) * 100).round()
        : 0;
    emit(KaraokeResult(
      score: score,
      totalLines: _lyrics.length,
      linesCompleted: _tappedCorrectly,
    ));
  }

  /// Judges a tap against the song position reported by the player, not the
  /// wall clock, so a song started (or seeked) at any time still scores fairly.
  void onLineTapped(int lineNumber, Duration playerPosition) {
    if (!_isRecording || _currentLineIndex < 0) return;

    _totalTaps++;

    final expectedLine = _lyrics[_currentLineIndex];
    final expectedPosition = _effectiveTime(expectedLine);
    final tolerance = Duration(
      milliseconds: (expectedPosition.inMilliseconds * 0.25).round(),
    );

    final diff = (playerPosition - expectedPosition).abs();

    if (diff <= tolerance) {
      _tappedCorrectly++;
    }

    final score = _totalTaps > 0
        ? ((_tappedCorrectly / _totalTaps) * 100).round()
        : 0;

    emit(KaraokeRecording(
      score: score,
      linesCompleted: _tappedCorrectly,
    ));
  }

  bool get isRecording => _isRecording;
}
