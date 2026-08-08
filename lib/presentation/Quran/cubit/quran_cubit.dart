import 'package:bloc/bloc.dart';
import 'package:hive/hive.dart';

import '../../../core/services/quran_catalog.dart';
import '../../../core/services/quran_resolver.dart';
import '../../../data/models/songs/songs_model.dart';
import '../../../data/sources/quran/quran_text_data_source.dart';
import 'quran_state.dart';

class QuranCubit extends Cubit<QuranState> {
  static const String _boxName = 'quran_progress';
  static const String _progressKey = 'progress';
  static const String _reciterKey = 'reciter';

  final QuranTextDataSource _textSource;

  QuranCubit({QuranTextDataSource? textSource})
      : _textSource = textSource ?? QuranTextDataSourceImpl(),
        super(const QuranInitial());

  List<QuranSurah> get surahs => QuranCatalog.surahs;

  Future<void> load() async {
    if (state is QuranLoaded) return;
    emit(const QuranLoading());
    final (reciter, progress) = await _readPersisted();
    final continueSurah = _findContinue(progress);
    emit(QuranLoaded(
      surahs: QuranCatalog.surahs,
      progress: progress,
      continueSurah: continueSurah,
      continuePositionMs:
          continueSurah != null ? (progress[continueSurah.number]?.positionMs ?? 0) : 0,
      reciter: reciter,
    ));
  }

  Future<void> setReciter(String reciter) async {
    await _saveReciter(reciter);
    final s = state;
    if (s is QuranLoaded) emit(s.copyWith(reciter: reciter));
  }

  /// Fetches ayah texts for [surahNumber]; falls back to bundled text.
  Future<List<String>> ayahsFor(int surahNumber) =>
      _textSource.fetchAyahs(surahNumber);

  QuranProgress? progressOf(int surahNumber) {
    final s = state;
    if (s is QuranLoaded) return s.progress[surahNumber];
    return null;
  }

  /// Builds a playable [SongModel] for [surah] using the selected reciter.
  SongModel songFor(QuranSurah surah) {
    final reciter =
        state is QuranLoaded ? (state as QuranLoaded).reciter : 'المنشاوي';
    return SongModel(
      id: 'quran_${surah.number}',
      title: 'سورة ${surah.arabicName}',
      artist: reciter,
      urlSongsbase: QuranResolver.urlFor(surah.number, reciter) ?? '',
      imageUrl: '',
      duration: '0:00',
      releaseDate: DateTime(2000),
      lyrics: '',
    );
  }

  Future<void> markPlayed(
      int surahNumber, int positionMs, int durationMs) async {
    final s = state;
    if (s is! QuranLoaded) return;

    final existing = s.progress[surahNumber] ?? const QuranProgress();
    final updated = existing.copyWith(
      positionMs: positionMs,
      durationMs: durationMs,
      playCount: existing.playCount + 1,
      lastPlayedAt: DateTime.now(),
      completed: existing.completed || (durationMs > 0 && positionMs >= durationMs * 0.98),
    );

    final progress = Map<int, QuranProgress>.from(s.progress)
      ..[surahNumber] = updated;
    await _saveProgress(progress);
    emit(s.copyWith(
      progress: progress,
      continueSurah: _findContinue(progress),
      continuePositionMs: _continuePositionMs(progress),
    ));
  }

  Future<void> markCompleted(int surahNumber) async {
    final s = state;
    if (s is! QuranLoaded) return;

    final existing = s.progress[surahNumber] ?? const QuranProgress();
    final progress = Map<int, QuranProgress>.from(s.progress)
      ..[surahNumber] = existing.copyWith(completed: true, positionMs: 0);
    await _saveProgress(progress);
    emit(s.copyWith(
      progress: progress,
      continueSurah: _findContinue(progress),
      continuePositionMs: _continuePositionMs(progress),
    ));
  }
  QuranSurah? _findContinue(Map<int, QuranProgress> progress) {
    QuranSurah? best;
    DateTime? bestTime;
    for (final entry in progress.entries) {
      final p = entry.value;
      if (p.completed || p.lastPlayedAt == null) continue;
      if (bestTime == null || p.lastPlayedAt!.isAfter(bestTime)) {
        bestTime = p.lastPlayedAt;
        best = QuranCatalog.byNumber(entry.key);
      }
    }
    return best;
  }

  int _continuePositionMs(Map<int, QuranProgress> progress) {
    final cont = _findContinue(progress);
    if (cont == null) return 0;
    return progress[cont.number]?.positionMs ?? 0;
  }

  Future<(String, Map<int, QuranProgress>)> _readPersisted() async {
    try {
      final box = await Hive.openBox(_boxName);
      final reciter = box.get(_reciterKey) as String? ?? 'المنشاوي';
      final raw = box.get(_progressKey);
      final progress = <int, QuranProgress>{};
      if (raw is Map) {
        raw.forEach((key, value) {
          if (value is Map) {
            final n = int.tryParse(key.toString());
            if (n != null) {
              progress[n] = QuranProgress.fromJson(
                  Map<String, dynamic>.from(value));
            }
          }
        });
      }
      return (reciter, progress);
    } catch (_) {
      return ('المنشاوي', <int, QuranProgress>{});
    }
  }

  Future<void> _saveProgress(Map<int, QuranProgress> progress) async {
    try {
      final box = await Hive.openBox(_boxName);
      final serialized = progress.map(
          (k, v) => MapEntry(k.toString(), v.toJson()));
      await box.put(_progressKey, serialized);
    } catch (_) {
      // Best-effort persistence.
    }
  }

  Future<void> _saveReciter(String reciter) async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_reciterKey, reciter);
    } catch (_) {
      // Best-effort persistence.
    }
  }
}
