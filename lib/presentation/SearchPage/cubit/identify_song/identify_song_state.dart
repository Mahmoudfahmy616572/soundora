import 'package:equatable/equatable.dart';
import 'package:soundora/data/sources/audd/models/audd_result_model.dart';

sealed class IdentifySongState extends Equatable {
  @override
  List<Object?> get props => [];
}

final class IdentifySongInitial extends IdentifySongState {}

final class IdentifySongListening extends IdentifySongState {}

final class IdentifySongIdentifying extends IdentifySongState {}

final class IdentifySongIdentified extends IdentifySongState {
  final AuddResultModel result;
  IdentifySongIdentified(this.result);

  @override
  List<Object?> get props => [result.title, result.artist];
}

final class IdentifySongNotFound extends IdentifySongState {}

final class IdentifySongError extends IdentifySongState {
  final String message;
  IdentifySongError(this.message);

  @override
  List<Object?> get props => [message];
}
