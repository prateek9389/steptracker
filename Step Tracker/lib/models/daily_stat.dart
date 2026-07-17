import 'package:cloud_firestore/cloud_firestore.dart';

class DailyStat {
  final String dateId; // YYYY-MM-DD
  final String uid;
  final int steps;
  final double distanceKm;
  final int calories;
  final int walkingTimeSeconds;
  final int activeMinutes;
  final bool goalCompleted;
  final DateTime date;
  
  // New premium fields
  final Map<String, int> hourlySteps;
  final String walkingStatus;
  final DateTime lastUpdated;
  final double progress;
  final int remainingSteps;

  DailyStat({
    required this.dateId,
    required this.uid,
    required this.steps,
    required this.distanceKm,
    required this.calories,
    required this.walkingTimeSeconds,
    required this.activeMinutes,
    required this.goalCompleted,
    required this.date,
    this.hourlySteps = const {},
    this.walkingStatus = 'Inactive',
    DateTime? lastUpdated,
    this.progress = 0.0,
    this.remainingSteps = 0,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory DailyStat.fromJson(Map<String, dynamic> json, String documentId) {
    return DailyStat(
      dateId: documentId,
      uid: json['uid'] as String? ?? '',
      steps: json['steps'] as int? ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      calories: json['calories'] as int? ?? 0,
      walkingTimeSeconds: json['walkingTimeSeconds'] as int? ?? 0,
      activeMinutes: json['activeMinutes'] as int? ?? 0,
      goalCompleted: json['goalCompleted'] as bool? ?? false,
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hourlySteps: (json['hourlySteps'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as int),
          ) ??
          {},
      walkingStatus: json['walkingStatus'] as String? ?? 'Inactive',
      lastUpdated: (json['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      remainingSteps: json['remainingSteps'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'steps': steps,
      'distanceKm': distanceKm,
      'calories': calories,
      'walkingTimeSeconds': walkingTimeSeconds,
      'activeMinutes': activeMinutes,
      'goalCompleted': goalCompleted,
      'date': Timestamp.fromDate(date),
      'hourlySteps': hourlySteps,
      'walkingStatus': walkingStatus,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'progress': progress,
      'remainingSteps': remainingSteps,
    };
  }

  DailyStat copyWith({
    String? uid,
    int? steps,
    double? distanceKm,
    int? calories,
    int? walkingTimeSeconds,
    int? activeMinutes,
    bool? goalCompleted,
    DateTime? date,
    Map<String, int>? hourlySteps,
    String? walkingStatus,
    DateTime? lastUpdated,
    double? progress,
    int? remainingSteps,
  }) {
    return DailyStat(
      dateId: dateId,
      uid: uid ?? this.uid,
      steps: steps ?? this.steps,
      distanceKm: distanceKm ?? this.distanceKm,
      calories: calories ?? this.calories,
      walkingTimeSeconds: walkingTimeSeconds ?? this.walkingTimeSeconds,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      goalCompleted: goalCompleted ?? this.goalCompleted,
      date: date ?? this.date,
      hourlySteps: hourlySteps ?? this.hourlySteps,
      walkingStatus: walkingStatus ?? this.walkingStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      progress: progress ?? this.progress,
      remainingSteps: remainingSteps ?? this.remainingSteps,
    );
  }
}
