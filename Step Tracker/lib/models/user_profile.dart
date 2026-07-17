import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final double height; // cm
  final double weight; // kg
  final int age;
  final String gender;
  final int dailyGoal;
  final double stepLength; // cm
  final DateTime createdAt;
  final DateTime lastLogin;
  final int coins;
  final int level;
  final int xp;
  final int currentStreak;
  final int totalRewards;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl = '',
    required this.height,
    required this.weight,
    required this.age,
    required this.gender,
    required this.dailyGoal,
    required this.stepLength,
    required this.createdAt,
    required this.lastLogin,
    this.coins = 0,
    this.level = 1,
    this.xp = 0,
    this.currentStreak = 0,
    this.totalRewards = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, String documentId) {
    return UserProfile(
      uid: documentId,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      height: (json['height'] as num?)?.toDouble() ?? 170.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 70.0,
      age: json['age'] as int? ?? 25,
      gender: json['gender'] as String? ?? 'Other',
      dailyGoal: json['dailyGoal'] as int? ?? 6000,
      stepLength: (json['stepLength'] as num?)?.toDouble() ?? 70.0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (json['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      coins: json['coins'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      totalRewards: json['totalRewards'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'height': height,
      'weight': weight,
      'age': age,
      'gender': gender,
      'dailyGoal': dailyGoal,
      'stepLength': stepLength,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'coins': coins,
      'level': level,
      'xp': xp,
      'currentStreak': currentStreak,
      'totalRewards': totalRewards,
    };
  }

  double get bmi {
    if (height <= 0) return 0.0;
    final heightMeters = height / 100.0;
    return weight / (heightMeters * heightMeters);
  }

  String get bmiCategory {
    final val = bmi;
    if (val < 18.5) return 'Underweight';
    if (val < 25.0) return 'Normal';
    if (val < 30.0) return 'Overweight';
    return 'Obese';
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? photoUrl,
    double? height,
    double? weight,
    int? age,
    String? gender,
    int? dailyGoal,
    double? stepLength,
    DateTime? lastLogin,
    int? coins,
    int? level,
    int? xp,
    int? currentStreak,
    int? totalRewards,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      stepLength: stepLength ?? this.stepLength,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      coins: coins ?? this.coins,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      currentStreak: currentStreak ?? this.currentStreak,
      totalRewards: totalRewards ?? this.totalRewards,
    );
  }
}
