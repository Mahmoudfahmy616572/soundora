import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_state.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

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
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAudioPlayer audioPlayer;
  late SongPlayerCubit cubit;

  setUpAll(() {
    registerFallbackValue(LoopMode.off);
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    audioPlayer = MockAudioPlayer();
    when(() => audioPlayer.playing).thenReturn(false);
    when(() => audioPlayer.positionStream)
        .thenAnswer((_) => const Stream<Duration>.empty());
    when(() => audioPlayer.durationStream)
        .thenAnswer((_) => const Stream<Duration>.empty());
    when(() => audioPlayer.playerStateStream)
        .thenAnswer((_) => const Stream<PlayerState>.empty());
    when(() => audioPlayer.currentIndexStream)
        .thenAnswer((_) => const Stream<int>.empty());
    when(() => audioPlayer.setLoopMode(any())).thenAnswer((_) async {});
    when(() => audioPlayer.setShuffleModeEnabled(any()))
        .thenAnswer((_) async {});
    when(() => audioPlayer.shuffle()).thenAnswer((_) async {});
    when(() => audioPlayer.play()).thenAnswer((_) async {});
    when(() => audioPlayer.pause()).thenAnswer((_) async {});
    when(() => audioPlayer.seek(any())).thenAnswer((_) async {});
    when(() => audioPlayer.stop()).thenAnswer((_) async {});
    when(() => audioPlayer.dispose()).thenAnswer((_) async {});
    when(() => audioPlayer.processingState).thenReturn(ProcessingState.ready);
    cubit = SongPlayerCubit(audioPlayerOverride: audioPlayer);
  });

  tearDown(() async {
    await cubit.close();
  });

  group('SongPlayerCubit', () {
    test('initial state is SongPlayerLoading', () {
      expect(cubit.state, isA<SongPlayerLoading>());
    });

    test('toggleRepeatMode cycles off -> one -> all -> off', () {
      cubit.toggleRepeatMode();
      expect(cubit.loopMode, LoopMode.one);
      verify(() => audioPlayer.setLoopMode(LoopMode.one)).called(1);
      expect(cubit.state, isA<SongPlayerLoaded>());

      cubit.toggleRepeatMode();
      expect(cubit.loopMode, LoopMode.all);
      verify(() => audioPlayer.setLoopMode(LoopMode.all)).called(1);

      cubit.toggleRepeatMode();
      expect(cubit.loopMode, LoopMode.off);
      verify(() => audioPlayer.setLoopMode(LoopMode.off)).called(1);
    });

    test('toggleShuffleMode enables shuffle and shuffles the queue', () async {
      cubit.toggleShuffleMode();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.isShuffleMode, isTrue);
      verify(() => audioPlayer.setShuffleModeEnabled(true)).called(1);
      verify(() => audioPlayer.shuffle()).called(1);

      clearInteractions(audioPlayer);

      cubit.toggleShuffleMode();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.isShuffleMode, isFalse);
      verify(() => audioPlayer.setShuffleModeEnabled(false)).called(1);
      verifyNever(() => audioPlayer.shuffle());
    });

    test('toggleShowLyrics flips lyrics visibility in state', () {
      cubit.toggleShowLyrics();
      expect((cubit.state as SongPlayerLoaded).isLyricsVisible, isTrue);
      cubit.toggleShowLyrics();
      expect((cubit.state as SongPlayerLoaded).isLyricsVisible, isFalse);
    });

    test('setLyricsVisible updates state', () {
      cubit.setLyricsVisible(true);
      expect((cubit.state as SongPlayerLoaded).isLyricsVisible, isTrue);
      cubit.setLyricsVisible(false);
      expect((cubit.state as SongPlayerLoaded).isLyricsVisible, isFalse);
    });

    test('updatePlaylist replaces the playlist in state', () {
      final songs = [_mockSong('1', 'Song 1'), _mockSong('2', 'Song 2')];
      cubit.updatePlaylist(songs);
      final state = cubit.state as SongPlayerLoaded;
      expect(state.playlist.length, 2);
      expect(state.playlist.first.title, 'Song 1');
    });

    test('playOrpauseSong plays when paused', () async {
      cubit.playOrpauseSong();
      await Future<void>.delayed(Duration.zero);
      verify(() => audioPlayer.play()).called(1);
      verifyNever(() => audioPlayer.pause());
    });

    test('playOrpauseSong pauses when playing', () async {
      when(() => audioPlayer.playing).thenReturn(true);
      cubit.playOrpauseSong();
      await Future<void>.delayed(Duration.zero);
      verify(() => audioPlayer.pause()).called(1);
      verifyNever(() => audioPlayer.play());
    });

    test('seekTo forwards the position to the player', () {
      cubit.seekTo(const Duration(seconds: 42));
      verify(() => audioPlayer.seek(const Duration(seconds: 42))).called(1);
    });

    test('upDateThemeColor falls back to default color for an empty url',
        () async {
      await cubit.upDateThemeColor('');
      expect(cubit.dominantColor, const Color(0xff121212));
    });

    test('position stream updates songPosition and emits state', () async {
      final controller = StreamController<Duration>.broadcast();
      when(() => audioPlayer.positionStream)
          .thenAnswer((_) => controller.stream);
      final c = SongPlayerCubit(audioPlayerOverride: audioPlayer);
      controller.add(const Duration(seconds: 5));
      await Future<void>.delayed(Duration.zero);
      expect(c.songPosition, const Duration(seconds: 5));
      expect(c.state, isA<SongPlayerLoaded>());
      await controller.close();
      await c.close();
    });
  });
}
