import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stride_ai/providers/stats_provider.dart';
import 'package:stride_ai/providers/dashboard_provider.dart';
import 'package:stride_ai/models/reward_history.dart';

class ChallengesAndRewardsRow extends ConsumerWidget {
  const ChallengesAndRewardsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 400) {
          // Mobile: stack vertically
          return Column(
            children: [
              _buildChallengesCard(context, ref),
              const SizedBox(height: 16),
              _buildRewardsCard(context, ref),
            ],
          );
        }
        // Tablet: Row
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildChallengesCard(context, ref)),
            const SizedBox(width: 16),
            Expanded(child: _buildRewardsCard(context, ref)),
          ],
        );
      }
    );
  }

  Widget _buildChallengesCard(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey[200]!;
    final primaryPurple = const Color(0xFF6324D6);
    
    final statsAsync = ref.watch(allDailyStatsStreamProvider);
    double weeklyDist = 0.0;
    
    if (statsAsync.hasValue && statsAsync.value != null) {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      for (var stat in statsAsync.value!) {
        if (stat.date.isAfter(weekAgo) || stat.date.isAtSameMomentAs(weekAgo)) {
          weeklyDist += stat.distanceKm;
        }
      }
    }
    
    double progress = (weeklyDist / 50.0).clamp(0.0, 1.0);
    int progressPercent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes_rounded, color: isDark ? Colors.blue[300] : Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text('Weekly Challenges', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('👑', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text('Walk 50 km', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, fontFamily: 'Outfit'),
                        children: [
                          TextSpan(text: '${weeklyDist.toStringAsFixed(1)} ', style: TextStyle(fontWeight: FontWeight.bold, color: primaryPurple)),
                          TextSpan(text: '/ 50 km', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                        ]
                      )
                    ),
                    Text('$progressPercent%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryPurple)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.grey[200], borderRadius: BorderRadius.circular(3)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(decoration: BoxDecoration(color: primaryPurple, borderRadius: BorderRadius.circular(3))),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Reward: ', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
                    const Icon(Icons.stars_rounded, color: Colors.orange, size: 14),
                    const SizedBox(width: 4),
                    const Text('300 Coins', style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRewardsCard(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey[200]!;
    
    final historyAsync = ref.watch(rewardHistoryStreamProvider);
    int weekCoins = 0;
    int weekXp = 0;
    String? latestBadgeTitle;

    if (historyAsync.hasValue && historyAsync.value != null) {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      for (var h in historyAsync.value!) {
        if (h.timestamp.isAfter(weekAgo)) {
          weekCoins += h.coinsEarned;
          weekXp += h.xpEarned;
          if (h.type == RewardHistoryType.badgeEarned && latestBadgeTitle == null) {
            latestBadgeTitle = h.title.replaceAll('Badge Unlocked: ', '').replaceAll('Achievement: ', '');
          }
        }
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard_rounded, color: Colors.pink[400], size: 20),
              const SizedBox(width: 8),
              Text('Rewards Earned (This Week)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRewardItem('+$weekCoins', 'Coins', Icons.stars_rounded, Colors.orange, isDark),
                _buildRewardItem('+$weekXp', 'XP', Icons.military_tech_rounded, const Color(0xFF6324D6), isDark),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(latestBadgeTitle ?? 'No Badge', style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis,),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Color(0xFF6324D6), shape: BoxShape.circle),
                      child: const Icon(Icons.directions_walk_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 6),
                    Text('Latest Badge', style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem(String value, String label, IconData icon, Color color, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit', color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
          ],
        ),
      ],
    );
  }
}
