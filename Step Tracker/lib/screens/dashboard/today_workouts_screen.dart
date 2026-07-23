import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/walk_session.dart';
import '../../widgets/detailed_steps_view.dart';

class TodayWorkoutsScreen extends StatelessWidget {
  final List<WalkSession> walks;
  final int firestoreSteps;
  final int totalAppSteps;
  final int goal;
  final Map<String, int> hourlySteps;
  final String walkingStatus;
  final int activeMinutes;
  final double distanceKm;
  final int calories;
  final VoidCallback? onRewardTap;

  const TodayWorkoutsScreen({
    super.key,
    required this.walks,
    required this.firestoreSteps,
    required this.totalAppSteps,
    required this.goal,
    required this.hourlySteps,
    required this.walkingStatus,
    required this.activeMinutes,
    required this.distanceKm,
    required this.calories,
    this.onRewardTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            toolbarHeight: 60,
            backgroundColor: isDark ? const Color(0xFF0F172A).withOpacity(0.75) : const Color(0xFFF9FAFB).withOpacity(0.85),
            elevation: 0,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isDark ? Colors.white24 : Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : Colors.black87, size: 20),
                ),
              ),
            ),
            title: Text(
              'Today\'s Steps',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
                fontSize: 22,
                letterSpacing: 0.2,
              ),
            ),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
              bottom: walks.isEmpty,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, walks.isEmpty ? 24.0 : 8.0),
                child: DetailedStepsView(
                  currentSteps: firestoreSteps,
                  goal: goal,
                  hourlySteps: hourlySteps,
                  walkingStatus: walkingStatus,
                  activeMinutes: activeMinutes,
                  distanceKm: distanceKm,
                  calories: calories,
                  onRewardTap: onRewardTap,
                ),
              ),
            ),
          ),
          if (walks.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
                child: Text('Today\'s Walks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 24.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final walk = walks[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFF6324D6).withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.directions_walk_rounded, color: Color(0xFF6324D6)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(walk.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                const SizedBox(height: 4),
                                Text('${walk.steps} steps • ${(walk.durationSeconds ~/ 60)} mins', style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${walk.distanceKm.toStringAsFixed(2)} km', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                              const SizedBox(height: 4),
                              Text('${walk.calories} kcal', style: TextStyle(fontSize: 12, color: const Color(0xFFF97316))),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: walks.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
