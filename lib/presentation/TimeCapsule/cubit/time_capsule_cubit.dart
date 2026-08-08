import 'package:bloc/bloc.dart';
import 'package:soundora/data/sources/listening_history/listening_data_source.dart';

class TimeCapsuleState {
  final bool isLoading;
  final List<PlayEvent> todayMemories;
  final List<PlayEvent> thisDayLastYear;
  final Map<String, int> yearSummary;

  const TimeCapsuleState({
    this.isLoading = false,
    this.todayMemories = const [],
    this.thisDayLastYear = const [],
    this.yearSummary = const {},
  });

  TimeCapsuleState copyWith({
    bool? isLoading,
    List<PlayEvent>? todayMemories,
    List<PlayEvent>? thisDayLastYear,
    Map<String, int>? yearSummary,
  }) {
    return TimeCapsuleState(
      isLoading: isLoading ?? this.isLoading,
      todayMemories: todayMemories ?? this.todayMemories,
      thisDayLastYear: thisDayLastYear ?? this.thisDayLastYear,
      yearSummary: yearSummary ?? this.yearSummary,
    );
  }
}

class TimeCapsuleCubit extends Cubit<TimeCapsuleState> {
  final ListeningDataSource _dataSource;

  TimeCapsuleCubit(ListeningDataSource? dataSource)
      : _dataSource = dataSource ?? ListeningDataSourceImpl(),
        super(const TimeCapsuleState());

  Future<void> loadCapsule() async {
    emit(const TimeCapsuleState(isLoading: true));
    final now = DateTime.now();
    final all = _dataSource.getPlayEvents(limit: 200);

    final todayMemories = <PlayEvent>[];
    final thisDayLastYear = <PlayEvent>[];
    final yearSummary = <String, int>{};

    for (final event in all) {
      final t = event.timestamp;
      if (t.month == now.month && t.day == now.day) {
        todayMemories.add(event);
        if (t.year == now.year - 1) {
          thisDayLastYear.add(event);
        }
      }
      if (t.year == now.year - 1) {
        final key = '${t.month}-${t.day}';
        yearSummary[key] = (yearSummary[key] ?? 0) + 1;
      }
    }

    emit(TimeCapsuleState(
      todayMemories: todayMemories,
      thisDayLastYear: thisDayLastYear,
      yearSummary: yearSummary,
    ));
  }
}
