import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:soundora/data/models/songs/songs_model.dart';
import 'package:soundora/data/sources/deezer/deezer_data_source.dart';
import 'package:soundora/presentation/Gamification/cubit/achievement_cubit.dart';
import 'package:soundora/serviece_locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'listening_party_state.dart';

/// Real listening-party rooms backed by Supabase Postgres + Realtime.
///
/// Requires a `listening_parties` table (SQL in the project docs):
/// every device writes to the row and receives Postgres change events, so a
/// room hosted on one phone is live on every device that joined with the code.
class ListeningPartyCubit extends Cubit<ListeningPartyState> {
  final DeezerDataSource _deezerDataSource;
  final Random _random = Random();

  ListeningPartyCubit({DeezerDataSource? deezerDataSource})
      : _deezerDataSource = deezerDataSource ?? DeezerDataSourceImpl(),
        super(ListeningPartyInitial());

  RealtimeChannel? _channel;
  String? _roomCode;
  String? _selfId;

  SupabaseClient get _supabase => Supabase.instance.client;

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      6,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
  }

  Future<void> createRoom(String hostName) async {
    emit(ListeningPartyLoading());
    try {
      final code = _generateRoomCode();
      final host = PartyParticipant(
        id: 'host_${DateTime.now().millisecondsSinceEpoch}',
        name: hostName,
        isHost: true,
      );
      _selfId = host.id;

      final row = await _supabase
          .from('listening_parties')
          .insert({
            'room_code': code,
            'host_name': hostName,
            'status': 'lobby',
            'participants': [host.toJson()],
          })
          .select()
          .single();

      try {
        getIt<AchievementCubit>().onPartyHosted();
      } catch (_) {}

      _roomCode = code;
      _listenToRoom(row['id'] as String, code);

      emit(ListeningPartyLobby(
        roomCode: code,
        participants: [host],
        isHost: true,
        hostName: hostName,
      ));
    } catch (e) {
      emit(ListeningPartyError('Failed to create room'));
    }
  }

  Future<void> joinRoom(String roomCode, String userName) async {
    emit(ListeningPartyLoading());
    try {
      final code = roomCode.trim().toUpperCase();
      final rows = await _supabase
          .from('listening_parties')
          .select()
          .eq('room_code', code);
      if (rows.isEmpty) {
        emit(ListeningPartyError('Room not found'));
        return;
      }

      final row = rows.first;
      final existing = _participantsFrom(row);
      final participant = PartyParticipant(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: userName,
      );
      _selfId = participant.id;

      final updated = [
        ...existing.where((p) => p.id != participant.id),
        participant,
      ];

      await _supabase
          .from('listening_parties')
          .update({
            'participants': updated.map((p) => p.toJson()).toList(),
          })
          .eq('id', row['id'].toString());

      _roomCode = code;
      _listenToRoom(row['id'] as String, code);

      emit(ListeningPartyLobby(
        roomCode: code,
        participants: updated,
        isHost: false,
        hostName: row['host_name']?.toString() ?? '',
      ));
    } catch (e) {
      emit(ListeningPartyError('Failed to join room'));
    }
  }

  Future<void> startParty() async {
    if (state is! ListeningPartyLobby) return;
    final lobby = state as ListeningPartyLobby;

    emit(ListeningPartyLoading());
    try {
      final songs = await _deezerDataSource.getTopTracks(limit: 20);
      if (songs.isEmpty) {
        emit(ListeningPartyError('No songs available'));
        return;
      }
      await _updateRow({
        'status': 'active',
        'queue': songs.map((s) => s.toJson()).toList(),
        'current_song': songs.first.toJson(),
        'current_index': 0,
        'is_playing': true,
      });
      emit(ListeningPartyActive(
        roomCode: lobby.roomCode,
        participants: lobby.participants,
        currentSong: songs.first,
        currentIndex: 0,
        queue: songs,
        isPlaying: true,
        isHost: lobby.isHost,
      ));
    } catch (e) {
      emit(ListeningPartyError('Failed to start party'));
    }
  }

  void playPause() {
    if (state is! ListeningPartyActive) return;
    final current = state as ListeningPartyActive;
    _updateRow({'is_playing': !current.isPlaying});
    emit(current.copyWith(isPlaying: !current.isPlaying));
  }

  void nextSong() {
    if (state is! ListeningPartyActive) return;
    final current = state as ListeningPartyActive;
    if (current.currentIndex >= current.queue.length - 1) return;
    final newIndex = current.currentIndex + 1;
    final song = current.queue[newIndex];
    _updateRow({
      'current_index': newIndex,
      'current_song': song.toJson(),
      'is_playing': true,
    });
    emit(current.copyWith(
      currentIndex: newIndex,
      currentSong: song,
      isPlaying: true,
    ));
  }

  void previousSong() {
    if (state is! ListeningPartyActive) return;
    final current = state as ListeningPartyActive;
    if (current.currentIndex <= 0) return;
    final newIndex = current.currentIndex - 1;
    final song = current.queue[newIndex];
    _updateRow({
      'current_index': newIndex,
      'current_song': song.toJson(),
      'is_playing': true,
    });
    emit(current.copyWith(
      currentIndex: newIndex,
      currentSong: song,
      isPlaying: true,
    ));
  }

  Future<void> leaveParty() async {
    await _channel?.unsubscribe();
    _channel = null;
    _roomCode = null;
    _selfId = null;
    emit(ListeningPartyInitial());
  }

  Future<void> _updateRow(Map<String, dynamic> values) async {
    final code = _roomCode;
    if (code == null) return;
    try {
      await _supabase
          .from('listening_parties')
          .update(values)
          .eq('room_code', code);
    } catch (_) {}
  }

  void _listenToRoom(String roomId, String code) {
    final channel = _supabase.channel('listening_party:$code');
    _channel = channel;
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'listening_parties',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_code',
            value: code,
          ),
          callback: (payload) {
            final record = Map<String, dynamic>.from(payload.newRecord);
            _applyServerState(record, code);
          },
        )
        .subscribe();
  }

  void _applyServerState(Map<String, dynamic> record, String code) {
    final participants = _participantsFrom(record);
    final isHost = _selfId != null &&
        participants.any((p) => p.id == _selfId && p.isHost);

    if (record['status']?.toString() == 'active') {
      final queue = _queueFrom(record);
      final song = record['current_song'] is Map
          ? SongModel.fromJson(
              Map<String, dynamic>.from(record['current_song'] as Map))
          : null;
      emit(ListeningPartyActive(
        roomCode: code,
        participants: participants,
        currentSong: song,
        currentIndex: (record['current_index'] as num?)?.toInt() ?? 0,
        queue: queue,
        isPlaying: record['is_playing'] == true,
        isHost: isHost,
      ));
    } else {
      emit(ListeningPartyLobby(
        roomCode: code,
        participants: participants,
        isHost: isHost,
        hostName: record['host_name']?.toString() ?? '',
      ));
    }
  }

  List<PartyParticipant> _participantsFrom(Map<String, dynamic> json) {
    final raw = json['participants'];
    if (raw is! List) return [];
    return raw
        .map((e) => PartyParticipant.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  List<SongModel> _queueFrom(Map<String, dynamic> json) {
    final raw = json['queue'];
    if (raw is! List) return [];
    return raw
        .map((e) => SongModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
