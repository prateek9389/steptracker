import 'package:flutter/material.dart';

class ChallengesAndRewardsRow extends StatelessWidget {
  const ChallengesAndRewardsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 400) {
          // Mobile: stack vertically
          return Column(
            children: [
              _buildChallengesCard(context),
              const SizedBox(height: 16),
              _buildRewardsCard(context),
            ],
          );
        }
        // Tablet: Row
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildChallengesCard(context)),
            const SizedBox(width: 16),
            Expanded(child: _buildRewardsCard(context)),
          ],
        );
      }
    );
  }

  Widget _buildChallengesCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey[200]!;
    final primaryPurple = const Color(0xFF6324D6);
    
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
                          TextSpan(text: '45.6 ', style: TextStyle(fontWeight: FontWeight.bold, color: primaryPurple)),
                          TextSpan(text: '/ 50 km', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                        ]
                      )
                    ),
                    Text('91%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryPurple)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.grey[200], borderRadius: BorderRadius.circular(3)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.91,
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

  Widget _buildRewardsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey[200]!;
    
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
              Text('Rewards Earned', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRewardItem('+250', 'Coins', Icons.stars_rounded, Colors.orange, isDark),
                _buildRewardItem('+100', 'XP', Icons.military_tech_rounded, const Color(0xFF6324D6), isDark),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Weekly Walker', style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Color(0xFF6324D6), shape: BoxShape.circle),
                      child: const Icon(Icons.directions_walk_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 6),
                    Text('Badge', style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54)),
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
