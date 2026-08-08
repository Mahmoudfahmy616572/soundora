import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/presentation/Queue/cubit/queue_cubit.dart';
import 'package:soundora/presentation/Queue/cubit/queue_state.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';

class MockSongPlayerCubit extends Mock implements SongPlayerCubit {}

SongModel _mockSong(String id, String title) => SongModel(
      id: id,
      title: title,
      artist: 'Artist $id',
      urlSongsbase: 'url_$id',
      imageUrl: 'img_$id',
      duration: '3:00',
      releaseDate: DateTime(2024),
      lyrics: '',
    );

void main() {
  late MockSongPlayerCubit mockPlayer;
  late QueueCubit queueCubit;

  setUp(() {
    mockPlayer = MockSongPlayerCubit();
    when(() => mockPlayer.playList).thenReturn([
      _mockSong('1', 'Song 1'),
      _mockSong('2', 'Song 2'),
      _mockSong('3', 'Song 3'),
      _mockSong('4', 'Song 4'),
    ]);
    when(() => mockPlayer.currentIndex).thenReturn(0);
    when(() => mockPlayer.updatePlaylist(any())).thenReturn(null);
    queueCubit = QueueCubit(mockPlayer);
  });

  tearDown(() {
    queueCubit.close();
  });

  group('QueueCubit', () {
    test('initial state is QueueInitial', () {
      expect(queueCubit.state, isA<QueueInitial>());
    });

    blocTest<QueueCubit, QueueState>(
      'loadQueue emits QueueLoaded with correct upNext',
      build: () => QueueCubit(mockPlayer),
      act: (cubit) => cubit.loadQueue(),
      expect: () => [
        isA<QueueLoaded>(),
      ],
      verify: (cubit) {
        final state = cubit.state as QueueLoaded;
        expect(state.upNext.length, 3);
        expect(state.upNext[0].title, 'Song 2');
        expect(state.currentPlayingIndex, 0);
      },
    );

    blocTest<QueueCubit, QueueState>(
      'reorderQueue reorders songs correctly',
      build: () => QueueCubit(mockPlayer),
      act: (cubit) {
        cubit.loadQueue();
        cubit.reorderQueue(0, 2);
      },
      verify: (cubit) {
        final state = cubit.state as QueueLoaded;
        expect(state.upNext[0].title, 'Song 3');
        expect(state.upNext[1].title, 'Song 2');
        expect(state.upNext[2].title, 'Song 4');
      },
    );

    blocTest<QueueCubit, QueueState>(
      'removeFromQueue removes song at index',
      build: () => QueueCubit(mockPlayer),
      act: (cubit) {
        cubit.loadQueue();
        cubit.removeFromQueue(1);
      },
      verify: (cubit) {
        final state = cubit.state as QueueLoaded;
        expect(state.upNext.length, 2);
      },
    );
  });
}
