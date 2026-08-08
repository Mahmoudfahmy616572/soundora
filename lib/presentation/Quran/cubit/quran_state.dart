import 'package:equatable/equatable.dart';
import 'package:soundora/core/services/quran_catalog.dart';

/// Listening/reading progress of a single surah.
class QuranProgress {
  final int positionMs;
  final int durationMs;
  final int playCount;
  final DateTime? lastPlayedAt;
  final bool completed;

  const QuranProgress({
    this.positionMs = 0,
    this.durationMs = 0,
    this.playCount = 0,
    this.lastPlayedAt,
    this.completed = false,
  });

  double get ratio {
    if (durationMs <= 0) return 0;
    return (positionMs / durationMs).clamp(0.0, 1.0);
  }

  QuranProgress copyWith({
    int? positionMs,
    int? durationMs,
    int? playCount,
    DateTime? lastPlayedAt,
    bool? completed,
  }) {
    return QuranProgress(
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      playCount: playCount ?? this.playCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'positionMs': positionMs,
        'durationMs': durationMs,
        'playCount': playCount,
        'lastPlayedAt': lastPlayedAt?.toIso8601String(),
        'completed': completed,
      };

  factory QuranProgress.fromJson(Map<String, dynamic> json) => QuranProgress(
        positionMs: (json['positionMs'] as num?)?.toInt() ?? 0,
        durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
        playCount: (json['playCount'] as num?)?.toInt() ?? 0,
        lastPlayedAt: json['lastPlayedAt'] is String
            ? DateTime.tryParse(json['lastPlayedAt'] as String)
            : null,
        completed: json['completed'] == true,
      );
}

abstract class QuranState extends Equatable {
  final String reciter;

  const QuranState({this.reciter = 'المنشاوي'});

  @override
  List<Object?> get props => [reciter];
}

class QuranInitial extends QuranState {
  const QuranInitial();
}

class QuranLoading extends QuranState {
  const QuranLoading({super.reciter});
}

class QuranLoaded extends QuranState {
  final List<QuranSurah> surahs;
  final Map<int, QuranProgress> progress;

  /// The most recently played (but not completed) surah.
  final QuranSurah? continueSurah;
  final int continuePositionMs;

  const QuranLoaded({
    required this.surahs,
    required this.progress,
    this.continueSurah,
    this.continuePositionMs = 0,
    super.reciter,
  });

  QuranLoaded copyWith({
    List<QuranSurah>? surahs,
    Map<int, QuranProgress>? progress,
    QuranSurah? continueSurah,
    int? continuePositionMs,
    String? reciter,
  }) {
    return QuranLoaded(
      surahs: surahs ?? this.surahs,
      progress: progress ?? this.progress,
      continueSurah: continueSurah ?? this.continueSurah,
      continuePositionMs: continuePositionMs ?? this.continuePositionMs,
      reciter: reciter ?? this.reciter,
    );
  }

  @override
  List<Object?> get props =>
      [reciter, surahs.length, progress, continueSurah?.number, continuePositionMs];
}
