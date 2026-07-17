class BadgeModel {
  final String id;
  final String title;
  final String description;
  final String iconCode; // Using icon identifiers since we don't have SVGs
  final String? assetPath; // New property for custom image badges
  final bool isUnlocked;
  final String? unlockDate;
  final double progress; // current value
  final double target;   // required value
  final String category; // 'Steps', 'Distance', 'Streak', etc.
  final int rewardCoins; // Coin reward for unlocking
  final int rewardXp;
  final bool isClaimed;  // Whether the coin reward has been claimed

  BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconCode,
    this.assetPath,
    this.isUnlocked = false,
    this.unlockDate,
    required this.progress,
    required this.target,
    required this.category,
    this.rewardCoins = 100, // Default reward coins
    this.rewardXp = 50,
    this.isClaimed = false,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json, String documentId) {
    return BadgeModel(
      id: documentId,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconCode: json['iconCode'] as String? ?? 'stars',
      assetPath: json['assetPath'] as String?,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockDate: json['unlockDate'] as String?,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      target: (json['target'] as num?)?.toDouble() ?? 1.0,
      category: json['category'] as String? ?? 'General',
      rewardCoins: json['rewardCoins'] as int? ?? 100,
      rewardXp: json['rewardXp'] as int? ?? 50,
      isClaimed: json['isClaimed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'iconCode': iconCode,
      'assetPath': assetPath,
      'isUnlocked': isUnlocked,
      'unlockDate': unlockDate,
      'progress': progress,
      'target': target,
      'category': category,
      'rewardCoins': rewardCoins,
      'rewardXp': rewardXp,
      'isClaimed': isClaimed,
    };
  }

  double get progressPercentage {
    if (target == 0) return 0.0;
    return (progress / target).clamp(0.0, 1.0);
  }

  BadgeModel copyWith({
    String? id,
    String? title,
    String? description,
    String? iconCode,
    String? assetPath,
    bool? isUnlocked,
    String? unlockDate,
    double? progress,
    double? target,
    String? category,
    int? rewardCoins,
    int? rewardXp,
    bool? isClaimed,
  }) {
    return BadgeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconCode: iconCode ?? this.iconCode,
      assetPath: assetPath ?? this.assetPath,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockDate: unlockDate ?? this.unlockDate,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      category: category ?? this.category,
      rewardCoins: rewardCoins ?? this.rewardCoins,
      rewardXp: rewardXp ?? this.rewardXp,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }
}
