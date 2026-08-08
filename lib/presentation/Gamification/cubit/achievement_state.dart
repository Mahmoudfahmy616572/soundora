import 'package:equatable/equatable.dart';
import 'package:soundora/presentation/Gamification/models/achievement_model.dart';

abstract class AchievementState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AchievementInitial extends AchievementState {}

class AchievementLoading extends AchievementState {}

class AchievementLoaded extends AchievementState {
  final List<AchievementModel> achievements;
  final int totalXp;
  final int level;

  AchievementLoaded({
    required this.achievements,
    this.totalXp = 0,
    this.level = 1,
  });

  int get unlockedCount => achievements.where((a) => a.isUnlocked).length;

  @override
  List<Object?> get props => [achievements, totalXp, level];
}

class AchievementFailure extends AchievementState {
  final String message;

  AchievementFailure(this.message);

  @override
  List<Object?> get props => [message];
}
