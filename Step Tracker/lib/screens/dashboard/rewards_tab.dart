import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_button.dart';
import '../../providers/reward_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/challenge.dart';
import '../../models/badge.dart';
import '../../models/reward.dart';
import '../../models/reward_history.dart';
import '../../services/reward_service.dart';
import '../../providers/profile_provider.dart';
import '../../repositories/achievement_repository.dart';

class RewardsTab extends ConsumerStatefulWidget {
  const RewardsTab({super.key});

  @override
  ConsumerState<RewardsTab> createState() => _RewardsTabState();
}

class _RewardsTabState extends ConsumerState<RewardsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RewardService _rewardService = RewardService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Added Store back in for completeness
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showBadgeDetails(BadgeModel badge) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(badge.assetPath != null ? 0 : 20),
                decoration: BoxDecoration(
                  color: badge.assetPath != null ? Colors.transparent : (badge.isUnlocked ? AppColors.primary.withOpacity(0.1) : Colors.white10),
                  shape: BoxShape.circle,
                ),
                child: badge.assetPath != null
                    ? Image.asset(
                        badge.assetPath!,
                        width: 80,
                        height: 80,
                        color: badge.isUnlocked ? null : Colors.black.withOpacity(0.7),
                        colorBlendMode: badge.isUnlocked ? null : BlendMode.saturation,
                      )
                    : Icon(
                        badge.isUnlocked ? Icons.stars_rounded : Icons.lock_outline_rounded,
                        size: 64,
                        color: badge.isUnlocked ? AppColors.primary : AppColors.textMutedDark,
                      ),
              ),
              const SizedBox(height: 20),
              Text(
                badge.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryDark),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: badge.progressPercentage,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 8),
              Text(
                '${badge.progress.toStringAsFixed(0)} / ${badge.target.toStringAsFixed(0)} (${(badge.progressPercentage * 100).toInt()}%)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
              ),
              if (badge.isUnlocked) ...[
                const SizedBox(height: 16),
                Text(
                  'Unlocked: ${badge.unlockDate}',
                  style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 24),
              CustomButton(
                text: 'Awesome',
                onPressed: () => Navigator.of(context).pop(),
                height: 48,
                type: ButtonType.primary,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPurchaseConfirm(String uid, int currentCoins, String rewardTitle, int cost) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final hasBalance = currentCoins >= cost;

        return Container(
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Claim Reward',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Would you like to redeem "$rewardTitle" for $cost Stride Coins?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (!hasBalance)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Insufficient coin balance. Keep walking to earn more!',
                    style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                      type: ButtonType.outline,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'Redeem',
                      onPressed: hasBalance
                          ? () async {
                              Navigator.of(context).pop();
                              try {
                                await _rewardService.purchaseReward(uid, currentCoins, cost, rewardTitle);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Reward claimed! Check your registered email for details.'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger),
                                );
                              }
                            }
                          : null,
                      type: ButtonType.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark, fontWeight: FontWeight.w600))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final userProfileAsync = ref.watch(profileStreamProvider);
    final userProfile = userProfileAsync.value;
    final challenges = ref.watch(activeChallengesStreamProvider);
    final badgesAsync = ref.watch(userBadgesStreamProvider);
    final historyAsync = ref.watch(rewardHistoryStreamProvider);
    final storeRewards = ref.watch(rewardStoreProvider);

    if (userProfile == null) return const Center(child: CircularProgressIndicator());

    int computedXp = 0;
    if (historyAsync.hasValue && historyAsync.value != null) {
      for (var h in historyAsync.value!) {
        computedXp += h.xpEarned;
      }
    }
    final currentXp = computedXp > userProfile.xp ? computedXp : userProfile.xp;
    final thresholds = {1:0, 2:100, 3:250, 4:450, 5:700, 6:1000, 7:1400, 8:1900, 9:2500, 10:3200};
    
    int currentLevel = 1;
    for (int i = 10; i >= 1; i--) {
      if (currentXp >= (thresholds[i] ?? 0)) {
        currentLevel = i;
        break;
      }
    }
    
    final currentLevelBase = thresholds[currentLevel] ?? 0;
    final nextLevelBase = thresholds[currentLevel + 1] ?? currentLevelBase;
    final xpInCurrentLevel = currentXp - currentLevelBase;
    final xpNeededForNext = nextLevelBase - currentLevelBase;
    final progressToNext = xpNeededForNext > 0 ? (xpInCurrentLevel / xpNeededForNext).clamp(0.0, 1.0) : 1.0;

    final badges = badgesAsync.value ?? [];
    final unlockedBadgesCount = badges.where((b) => b.isUnlocked).length;
    final completedChallengesCount = challenges.where((c) => c.isCompleted).length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkBgGradient : const LinearGradient(
            colors: [Color(0xFFF1F5F9), Color(0xFFF8FAFC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: false,
                  floating: true,
                  snap: true,
                  backgroundColor: innerBoxIsScrolled
                      ? (isDark ? AppColors.backgroundDark : const Color(0xFFF1F5F9))
                      : Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  titleSpacing: 24.0,
                  toolbarHeight: 60.0,
                  title: Text(
                    'Rewards & Badges',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top level profile card
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              if (isDark)
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.15),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                )
                            ],
                          ),
                          child: GlassCard(
                            borderColor: AppColors.primary.withOpacity(0.4),
                            padding: const EdgeInsets.all(24),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [AppColors.primary.withOpacity(0.2), const Color(0xFF0F172A)]
                                  : [Colors.white, AppColors.primary.withOpacity(0.05)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [AppColors.secondary, Color(0xFF10B981)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.secondary.withOpacity(0.4),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Lvl\n$currentLevel',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13, height: 1.1),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('TOTAL XP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                            const SizedBox(height: 4),
                                            Text('$currentXp ${currentLevel < 10 ? "/ $nextLevelBase XP" : "XP (Max Level)"}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryDark, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('TOTAL COINS', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.monetization_on_rounded, color: AppColors.primary, size: 20),
                                            const SizedBox(width: 6),
                                            Text('${userProfile.coins}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                                          ],
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                                if (currentLevel < 10) ...[
                                  const SizedBox(height: 16),
                                  LinearProgressIndicator(
                                    value: progressToNext,
                                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              const SizedBox(height: 20),
                              const Divider(color: Colors.white10),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatColumn('Streak', '${userProfile.currentStreak} Days', Icons.local_fire_department_rounded, AppColors.danger),
                                  _buildStatColumn('Badges', '$unlockedBadgesCount', Icons.stars_rounded, const Color(0xFFF59E0B)),
                                  _buildStatColumn('Challenges', '$completedChallengesCount', Icons.emoji_events_rounded, const Color(0xFF8B5CF6)),
                                  _buildStatColumn('Rewards', '${userProfile.totalRewards}', Icons.card_giftcard_rounded, AppColors.secondary),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Active Challenges'),
                      Tab(text: 'Achievements'),
                      Tab(text: 'Recent Rewards'),
                      Tab(text: 'Store'),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Challenges
                challenges.isEmpty
                    ? const Center(child: Text("No challenges right now."))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 110.0),
                        itemCount: challenges.length,
                        itemBuilder: (context, idx) {
                          final challenge = challenges[idx];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          challenge.title,
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.monetization_on_rounded, color: AppColors.primary, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            '+${challenge.rewardCoins}',
                                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.upgrade_rounded, color: AppColors.secondary, size: 16),
                                          const SizedBox(width: 2),
                                          Text(
                                            '+${challenge.rewardXp} XP',
                                            style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    challenge.description,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 16),
                                  LinearProgressIndicator(
                                    value: challenge.progressPercentage,
                                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Progress: ${challenge.progress.toStringAsFixed(0)} / ${challenge.target.toStringAsFixed(0)}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (challenge.isCompleted)
                                        const Text(
                                          'Completed',
                                          style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                                        )
                                      else if (!challenge.isJoined)
                                        OutlinedButton(
                                          onPressed: () {
                                            ref.read(challengeRepositoryProvider).joinChallenge(userProfile.uid, challenge.id);
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            side: const BorderSide(color: AppColors.primary),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: const Text('Join'),
                                        )
                                      else
                                        const Text(
                                          'In Progress',
                                          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                // Tab 2: Achievements (Badges)
                badgesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                  data: (badgesList) {
                    if (badgesList.isEmpty) {
                      // Auto-initialize default badges if the user has none
                      final user = ref.read(currentUserProvider);
                      if (user != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref.read(achievementRepositoryProvider).initUserBadges(
                            user.uid, 
                            AchievementRepository.getDefaultBadges()
                          );
                        });
                      }
                      return const Center(child: Text("Setting up your badges..."));
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 110.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: badgesList.length,
                      itemBuilder: (context, idx) {
                        final badge = badgesList[idx];
                        return InkWell(
                          onTap: () => _showBadgeDetails(badge),
                          borderRadius: BorderRadius.circular(24),
                          child: GlassCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(badge.assetPath != null ? 0 : 12),
                                  decoration: BoxDecoration(
                                    color: badge.assetPath != null ? Colors.transparent : (badge.isUnlocked ? AppColors.primary.withOpacity(0.15) : Colors.white10),
                                    shape: BoxShape.circle,
                                    boxShadow: badge.isUnlocked ? [
                                      BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))
                                    ] : null,
                                    border: badge.assetPath != null ? null : Border.all(
                                      color: badge.isUnlocked ? AppColors.primary.withOpacity(0.5) : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: badge.assetPath != null
                                      ? Image.asset(
                                          badge.assetPath!,
                                          width: 56,
                                          height: 56,
                                          color: badge.isUnlocked ? null : Colors.black.withOpacity(0.7),
                                          colorBlendMode: badge.isUnlocked ? null : BlendMode.saturation,
                                        )
                                      : Icon(
                                          badge.isUnlocked ? Icons.stars_rounded : Icons.lock_outline_rounded,
                                          size: 40,
                                          color: badge.isUnlocked ? AppColors.primary : AppColors.textMutedDark,
                                        ),
                                ),
                                const SizedBox(height: 16),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    badge.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    badge.category.toUpperCase(),
                                    style: const TextStyle(color: AppColors.secondary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (badge.isUnlocked)
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Unlocked',
                                        style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  )
                                else ...[
                                  Text(
                                    '${(badge.progressPercentage * 100).toInt()}% Done',
                                    style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Reward: +${badge.rewardCoins} Coins | +${badge.rewardXp} XP',
                                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 8, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                // Tab 3: Recent Rewards Timeline
                historyAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                  data: (historyList) {
                    if (historyList.isEmpty) return const Center(child: Text("No rewards yet. Start walking!"));
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 110.0),
                      itemCount: historyList.length,
                      itemBuilder: (context, idx) {
                        final history = historyList[idx];
                        IconData icon;
                        Color color;
                        switch (history.type) {
                          case RewardHistoryType.goalCompleted:
                            icon = Icons.flag_rounded; color = AppColors.success; break;
                          case RewardHistoryType.challengeCompleted:
                            icon = Icons.emoji_events_rounded; color = const Color(0xFF8B5CF6); break;
                          case RewardHistoryType.badgeEarned:
                            icon = Icons.stars_rounded; color = const Color(0xFFF59E0B); break;
                          case RewardHistoryType.streakIncreased:
                            icon = Icons.local_fire_department_rounded; color = AppColors.danger; break;
                          case RewardHistoryType.distanceMilestone:
                            icon = Icons.map_rounded; color = AppColors.secondary; break;
                          case RewardHistoryType.itemPurchased:
                            icon = Icons.shopping_bag_rounded; color = AppColors.textMutedDark; break;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15), 
                                    shape: BoxShape.circle,
                                    border: Border.all(color: color.withOpacity(0.3), width: 1),
                                  ),
                                  child: Icon(icon, color: color, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(history.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 4),
                                      Text(history.timestamp.toString().substring(0, 16), style: const TextStyle(fontSize: 10, color: AppColors.textMutedDark)),
                                    ],
                                  ),
                                ),
                                if (history.coinsEarned != 0 || history.xpEarned != 0) ...[
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (history.coinsEarned != 0)
                                        Row(
                                          children: [
                                            Text(history.coinsEarned > 0 ? '+${history.coinsEarned}' : '${history.coinsEarned}', style: TextStyle(fontWeight: FontWeight.bold, color: history.coinsEarned > 0 ? AppColors.success : AppColors.danger)),
                                            const SizedBox(width: 2),
                                            const Icon(Icons.monetization_on_rounded, size: 12, color: AppColors.primary),
                                          ],
                                        ),
                                      if (history.xpEarned > 0)
                                        Row(
                                          children: [
                                            Text('+${history.xpEarned}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 10)),
                                            const SizedBox(width: 2),
                                            const Text('XP', style: TextStyle(color: AppColors.secondary, fontSize: 8, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                    ],
                                  )
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                // Tab 4: Store
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 110.0),
                  itemCount: storeRewards.length,
                  itemBuilder: (context, idx) {
                    final reward = storeRewards[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withOpacity(0.2),
                                      AppColors.primary.withOpacity(0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
                                ),
                                child: Icon(
                                  reward.category == RewardCategory.giftCards
                                      ? Icons.card_giftcard_rounded
                                      : reward.category == RewardCategory.subscriptions
                                          ? Icons.card_membership_rounded
                                          : Icons.fitness_center_rounded,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          reward.providerName.toUpperCase(),
                                          style: const TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.monetization_on_rounded, color: AppColors.primary, size: 14),
                                            const SizedBox(width: 4),
                                            Text('${reward.coinCost}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(reward.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(reward.description, style: theme.textTheme.bodySmall),
                                    const SizedBox(height: 12),
                                    CustomButton(
                                      text: 'Redeem Reward',
                                      onPressed: () => _showPurchaseConfirm(userProfile.uid, userProfile.coins, reward.title, reward.coinCost),
                                      height: 38,
                                      type: ButtonType.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
