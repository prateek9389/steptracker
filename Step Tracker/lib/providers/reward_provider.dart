import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reward_history.dart';
import '../models/badge.dart';
import '../models/reward.dart';
import '../repositories/reward_repository.dart';
import '../repositories/achievement_repository.dart';
import 'auth_provider.dart';

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  return RewardRepository();
});

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepository();
});

final rewardHistoryStreamProvider = StreamProvider<List<RewardHistory>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  final repo = ref.watch(rewardRepositoryProvider);
  return repo.streamRewardHistory(user.uid);
});

final userBadgesStreamProvider = StreamProvider<List<BadgeModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  final repo = ref.watch(achievementRepositoryProvider);
  return repo.streamUserBadges(user.uid);
});

// Since rewards in the "Rewards Store" are static in the dummy data and user didn't mention a 'rewards store' collection in the prompt, 
// we will just keep a static list for the Rewards Store for them to purchase from.
final rewardStoreProvider = Provider<List<Reward>>((ref) {
  return [
    Reward(
      id: 'r1',
      title: 'Nike Performance Running Socks',
      description: 'Dri-FIT tech to keep feet dry and comfortable.',
      coinCost: 500,
      providerName: 'Nike',
      category: RewardCategory.fitnessGear,
      imagePath: 'assets/rewards/socks.png',
    ),
    Reward(
      id: 'r2',
      title: '\$20 Apple Gift Card',
      description: 'Use for apps, music, movies, and subscription upgrades.',
      coinCost: 1200,
      providerName: 'Apple',
      category: RewardCategory.giftCards,
      imagePath: 'assets/rewards/apple_card.png',
    ),
    Reward(
      id: 'r3',
      title: 'Premium Hydration Flask 32oz',
      description: 'Vacuum-insulated stainless steel water bottle.',
      coinCost: 800,
      providerName: 'StrideGear',
      category: RewardCategory.fitnessGear,
      imagePath: 'assets/rewards/flask.png',
    ),
    Reward(
      id: 'r4',
      title: '1-Month Strava Subscription',
      description: 'Unlock advanced routing, segments, and deep stats.',
      coinCost: 400,
      providerName: 'Strava',
      category: RewardCategory.subscriptions,
      imagePath: 'assets/rewards/strava.png',
    ),
  ];
});
