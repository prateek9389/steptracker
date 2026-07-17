import 'package:cloud_firestore/cloud_firestore.dart';

enum RewardHistoryType {
  goalCompleted,
  challengeCompleted,
  badgeEarned,
  streakIncreased,
  distanceMilestone,
  itemPurchased,
}

class RewardHistory {
  final String id;
  final String title;
  final RewardHistoryType type;
  final int coinsEarned;
  final int xpEarned;
  final DateTime timestamp;

  RewardHistory({
    required this.id,
    required this.title,
    required this.type,
    this.coinsEarned = 0,
    this.xpEarned = 0,
    required this.timestamp,
  });

  factory RewardHistory.fromJson(Map<String, dynamic> json, String documentId) {
    return RewardHistory(
      id: documentId,
      title: json['title'] as String? ?? '',
      type: RewardHistoryType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'goalCompleted'),
        orElse: () => RewardHistoryType.goalCompleted,
      ),
      coinsEarned: json['coinsEarned'] as int? ?? 0,
      xpEarned: json['xpEarned'] as int? ?? 0,
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type.name,
      'coinsEarned': coinsEarned,
      'xpEarned': xpEarned,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
