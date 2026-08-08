import 'package:equatable/equatable.dart';
import 'package:soundora/data/models/songs/songs_model.dart';

class PartyParticipant extends Equatable {
  final String id;
  final String name;
  final bool isHost;

  const PartyParticipant({
    required this.id,
    required this.name,
    this.isHost = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isHost': isHost,
      };

  factory PartyParticipant.fromJson(Map<String, dynamic> json) {
    return PartyParticipant(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isHost: json['isHost'] == true,
    );
  }

  @override
  List<Object?> get props => [id, name, isHost];
}

class ListeningPartyState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ListeningPartyInitial extends ListeningPartyState {}

class ListeningPartyLoading extends ListeningPartyState {}

class ListeningPartyLobby extends ListeningPartyState {
  final String roomCode;
  final List<PartyParticipant> participants;
  final bool isHost;
  final String hostName;

  ListeningPartyLobby({
    required this.roomCode,
    this.participants = const [],
    this.isHost = false,
    this.hostName = '',
  });

  @override
  List<Object?> get props => [roomCode, participants, isHost, hostName];
}

class ListeningPartyActive extends ListeningPartyState {
  final String roomCode;
  final List<PartyParticipant> participants;
  final SongModel? currentSong;
  final int currentIndex;
  final List<SongModel> queue;
  final bool isPlaying;
  final bool isHost;

  ListeningPartyActive({
    required this.roomCode,
    this.participants = const [],
    this.currentSong,
    this.currentIndex = 0,
    this.queue = const [],
    this.isPlaying = false,
    this.isHost = false,
  });

  ListeningPartyActive copyWith({
    List<PartyParticipant>? participants,
    SongModel? currentSong,
    int? currentIndex,
    List<SongModel>? queue,
    bool? isPlaying,
    bool? isHost,
  }) {
    return ListeningPartyActive(
      roomCode: roomCode,
      participants: participants ?? this.participants,
      currentSong: currentSong ?? this.currentSong,
      currentIndex: currentIndex ?? this.currentIndex,
      queue: queue ?? this.queue,
      isPlaying: isPlaying ?? this.isPlaying,
      isHost: isHost ?? this.isHost,
    );
  }

  @override
  List<Object?> get props =>
      [roomCode, participants, currentSong, currentIndex, queue, isPlaying];
}

class ListeningPartyError extends ListeningPartyState {
  final String message;

  ListeningPartyError(this.message);

  @override
  List<Object?> get props => [message];
}
