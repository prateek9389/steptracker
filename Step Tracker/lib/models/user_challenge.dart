class UserChallenge {
  final String challengeId;
  final double progress;
  final bool isCompleted;
  final DateTime? completedAt;
  final bool isClaimed;

  UserChallenge({
    required this.challengeId,
    this.progress = 0.0,
    this.isCompleted = false,
    this.completedAt,
    this.isClaimed = false,
  });

  factory UserChallenge.fromJson(Map<String, dynamic> json, String documentId) {
    return UserChallenge(
      challengeId: documentId,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      isClaimed: json['isClaimed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'progress': progress,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'isClaimed': isClaimed,
    };
  }

  UserChallenge copyWith({
    String? challengeId,
    double? progress,
    bool? isCompleted,
    DateTime? completedAt,
    bool? isClaimed,
  }) {
    return UserChallenge(
      challengeId: challengeId ?? this.challengeId,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }
}
