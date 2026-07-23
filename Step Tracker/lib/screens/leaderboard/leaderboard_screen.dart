import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../models/leaderboard_user.dart';
import '../../providers/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final globalState = ref.watch(leaderboardProvider);
    final friendsState = ref.watch(friendsLeaderboardProvider);
    final cityState = ref.watch(cityLeaderboardProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius:
            const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        border: Border.all(
          color: isDark ? const Color(0x1AFFFFFF) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Leaderboard',
                      style: theme.textTheme.displaySmall?.copyWith(
                          fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Friends'),
              Tab(text: 'My City'),
              Tab(text: 'Global'),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Friends tab
                friendsState.when(
                  data: (users) => _buildLeaderboardList(
                    users,
                    isDark,
                    emptyMessage:
                        'No friends found.\nAdd friends to see them here.',
                  ),
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) =>
                      Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.danger))),
                ),

                // City tab
                cityState.when(
                  data: (users) => _buildLeaderboardList(
                    users,
                    isDark,
                    emptyMessage:
                        'No city leaderboard yet.\nUpdate your city in your profile to see local rankings.',
                  ),
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) =>
                      Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.danger))),
                ),

                // Global tab
                globalState.when(
                  data: (users) => _buildLeaderboardList(
                    users,
                    isDark,
                    emptyMessage: 'No users found on the global leaderboard yet.',
                  ),
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) =>
                      Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.danger))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(
    List<LeaderboardUser> users,
    bool isDark, {
    required String emptyMessage,
  }) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            emptyMessage,
            style: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: users.length,
      itemBuilder: (context, idx) {
        final u = users[idx];

        Color rankColor = AppColors.textSecondaryDark;
        if (u.rank == 1) rankColor = const Color(0xFFFFD700);
        if (u.rank == 2) rankColor = const Color(0xFFC0C0C0);
        if (u.rank == 3) rankColor = const Color(0xFFCD7F32);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlassCard(
            borderColor: u.isCurrentUser ? AppColors.primary.withOpacity(0.4) : null,
            gradient: u.isCurrentUser
                ? LinearGradient(colors: isDark
                    ? [const Color(0xFF132F23), const Color(0xFF0B1220)]
                    : [Colors.white, const Color(0xFFE8FDF0)])
                : null,
            child: Row(
              children: [
                // Rank
                SizedBox(
                  width: 36,
                  child: Center(
                    child: Text(
                      '${u.rank}',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w900,
                        fontSize: u.rank <= 3 ? 20 : 14,
                        color: rankColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Avatar — show real photo if available, else icon
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      u.isCurrentUser ? AppColors.primary.withOpacity(0.2) : Colors.white12,
                  backgroundImage:
                      u.avatarUrl.isNotEmpty && u.avatarUrl.startsWith('http')
                          ? NetworkImage(u.avatarUrl)
                          : null,
                  child: u.avatarUrl.isNotEmpty && u.avatarUrl.startsWith('http')
                      ? null
                      : Icon(Icons.person,
                          color: u.isCurrentUser ? AppColors.primary : Colors.white70),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.isCurrentUser ? '${u.name} (You)' : u.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: u.isCurrentUser ? AppColors.primary : Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            u.rankChange > 0
                                ? Icons.arrow_upward_rounded
                                : u.rankChange < 0
                                    ? Icons.arrow_downward_rounded
                                    : Icons.remove_rounded,
                            size: 10,
                            color: u.rankChange > 0
                                ? AppColors.success
                                : u.rankChange < 0
                                    ? AppColors.danger
                                    : AppColors.textMutedDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            u.rankChange == 0
                                ? 'No change'
                                : '${u.rankChange.abs()} ranks',
                            style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textMutedDark,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // XP
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${u.xp}',
                      style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white),
                    ),
                    const Text(
                      'XP',
                      style: TextStyle(
                          fontSize: 9,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
