import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stride_ai/theme/app_colors.dart';
import 'package:stride_ai/providers/walk_provider.dart';
import 'package:stride_ai/providers/stats_provider.dart';

import 'tabs/calories_tab.dart';
import 'tabs/distance_tab.dart';
import 'tabs/active_time_tab.dart';
import 'tabs/average_pace_tab.dart';

class ActivityDetailsScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const ActivityDetailsScreen({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  ConsumerState<ActivityDetailsScreen> createState() =>
      _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends ConsumerState<ActivityDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
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
    
    final walkHistoryAsync = ref.watch(walkHistoryStreamProvider);
    final dailyStatsAsync = ref.watch(allDailyStatsStreamProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
        title: Text(
          'Activity Details',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'Outfit',
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: '🔥 Calories'),
            Tab(text: '📍 Distance'),
            Tab(text: '⏱ Active Time'),
            Tab(text: '🚶 Avg Pace'),
          ],
        ),
      ),
      body: walkHistoryAsync.when(
        data: (walks) {
          return dailyStatsAsync.when(
            data: (dailyStats) {
              return TabBarView(
                controller: _tabController,
                children: [
                  CaloriesTab(walks: walks, dailyStats: dailyStats),
                  DistanceTab(walks: walks, dailyStats: dailyStats),
                  ActiveTimeTab(walks: walks, dailyStats: dailyStats),
                  AveragePaceTab(walks: walks, dailyStats: dailyStats),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
