class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int requiredValue;
  final int currentProgress;
  final bool isUnlocked;
  final int xpReward;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.requiredValue = 1,
    this.currentProgress = 0,
    this.isUnlocked = false,
    this.xpReward = 100,
  });

  double get progress =>
      requiredValue > 0 ? (currentProgress / requiredValue).clamp(0.0, 1.0) : 0.0;

  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    int? requiredValue,
    int? currentProgress,
    bool? isUnlocked,
    int? xpReward,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      requiredValue: requiredValue ?? this.requiredValue,
      currentProgress: currentProgress ?? this.currentProgress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      xpReward: xpReward ?? this.xpReward,
    );
  }

  static List<AchievementModel> defaultAchievements() {
    return const [
      AchievementModel(
        id: 'first_listen',
        title: 'First Listen',
        description: 'Listen to your very first song',
        icon: '🎵',
        requiredValue: 1,
        xpReward: 50,
      ),
      AchievementModel(
        id: 'night_owl',
        title: 'Night Owl',
        description: 'Listen after midnight 10 times',
        icon: '🦉',
        requiredValue: 10,
        xpReward: 150,
      ),
      AchievementModel(
        id: 'superfan',
        title: 'Superfan',
        description: 'Play the same artist 100 times',
        icon: '⭐',
        requiredValue: 100,
        xpReward: 300,
      ),
      AchievementModel(
        id: 'discovery_king',
        title: 'Discovery King',
        description: 'Discover 100 new songs',
        icon: '👑',
        requiredValue: 100,
        xpReward: 350,
      ),
      AchievementModel(
        id: 'streak',
        title: 'Streak',
        description: 'Listen to music 7 days in a row',
        icon: '🔥',
        requiredValue: 7,
        xpReward: 200,
      ),
      AchievementModel(
        id: 'curator',
        title: 'Curator',
        description: 'Save 20 songs to your library',
        icon: '📚',
        requiredValue: 20,
        xpReward: 250,
      ),
      AchievementModel(
        id: 'party_host',
        title: 'Party Host',
        description: 'Host your first listening party',
        icon: '🎉',
        requiredValue: 1,
        xpReward: 150,
      ),
    ];
  }
}
