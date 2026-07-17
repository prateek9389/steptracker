enum ChallengeType {
  daily,
  weekly,
  monthly,
  specialEvent,
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final int rewardCoins;
  final int rewardXp;
  final double progress; // current value
  final double target; // target value
  final ChallengeType type;
  final bool isJoined;
  final bool isCompleted;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardCoins,
    this.rewardXp = 50,
    required this.progress,
    required this.target,
    required this.type,
    this.isJoined = false,
    this.isCompleted = false,
  });

  factory Challenge.fromJson(Map<String, dynamic> json, String documentId) {
    return Challenge(
      id: documentId,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      rewardCoins: json['rewardCoins'] as int? ?? 100,
      rewardXp: json['rewardXp'] as int? ?? 50,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      target: (json['target'] as num?)?.toDouble() ?? 100.0,
      type: ChallengeType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'daily'),
        orElse: () => ChallengeType.daily,
      ),
      isJoined: json['isJoined'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'rewardCoins': rewardCoins,
      'rewardXp': rewardXp,
      'progress': progress,
      'target': target,
      'type': type.name,
      'isJoined': isJoined,
      'isCompleted': isCompleted,
    };
  }

  double get progressPercentage {
    if (target == 0) return 0.0;
    return (progress / target).clamp(0.0, 1.0);
  }

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    int? rewardCoins,
    int? rewardXp,
    double? progress,
    double? target,
    ChallengeType? type,
    bool? isJoined,
    bool? isCompleted,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      rewardCoins: rewardCoins ?? this.rewardCoins,
      rewardXp: rewardXp ?? this.rewardXp,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      type: type ?? this.type,
      isJoined: isJoined ?? this.isJoined,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
