enum RewardCategory {
  fitnessGear,
  giftCards,
  healthProducts,
  subscriptions,
}

class Reward {
  final String id;
  final String title;
  final String description;
  final int coinCost;
  final String providerName;
  final RewardCategory category;
  final String imagePath;
  final bool isClaimed;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.coinCost,
    required this.providerName,
    required this.category,
    required this.imagePath,
    this.isClaimed = false,
  });

  Reward copyWith({
    String? id,
    String? title,
    String? description,
    int? coinCost,
    String? providerName,
    RewardCategory? category,
    String? imagePath,
    bool? isClaimed,
  }) {
    return Reward(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coinCost: coinCost ?? this.coinCost,
      providerName: providerName ?? this.providerName,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }
}
