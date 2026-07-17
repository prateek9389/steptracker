import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../providers/dashboard_provider.dart';
import 'package:stride_ai/providers/auth_provider.dart';
import 'package:stride_ai/providers/notification_provider.dart';
import 'dart:async';
import 'home_tab.dart';
import 'walk_tab.dart';
import 'history_tab.dart';
import 'rewards_tab.dart';
import 'profile_tab.dart';

class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({super.key});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  final List<Widget> _tabs = [
    const HomeTab(),
    const HistoryTab(),
    const WalkTab(),
    const RewardsTab(),
    const ProfileTab(),
  ];
  @override
  void initState() {
    super.initState();
    // Socket initialization removed
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onItemTapped(int index) {
    ref.read(dashboardTabIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(dashboardTabIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true, // Allows content to show behind glass nav bar
      body: IndexedStack(
        index: selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Navigation Bar Background
          Container(
            height: 74,
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: GlassCard(
              blur: 10.0,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              borderRadius: 28,
              borderColor: isDark ? const Color(0x2BFFFFFF) : const Color(0x1F000000),
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFA111827), const Color(0xF91F2937)]
                    : [const Color(0xFAFFFFFF), const Color(0xF9F1F5F9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(selectedIndex, 0, Icons.home_rounded, 'Home'),
                  _buildNavItem(selectedIndex, 1, Icons.history_rounded, 'History'),
                  
                  // Space placeholder for the floating action button
                  const SizedBox(width: 60),

                  _buildNavItem(selectedIndex, 3, Icons.emoji_events_rounded, 'Rewards'),
                  _buildNavItem(selectedIndex, 4, Icons.person_rounded, 'Profile'),
                ],
              ),
            ),
          ),

          // Floating Middle Walk Button
          Positioned(
            bottom: 60, // Positioned half-way above the top bar edge
            child: GestureDetector(
              onTap: () => _onItemTapped(2),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: selectedIndex == 2
                      ? AppColors.neonAccentGradient
                      : LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                              : [Colors.white, const Color(0xFFE2E8F0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  border: Border.all(
                    color: selectedIndex == 2
                        ? Colors.white.withOpacity(0.3)
                        : (isDark ? AppColors.primary.withOpacity(0.35) : AppColors.primary.withOpacity(0.6)),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(selectedIndex == 2 ? 0.45 : 0.2),
                      blurRadius: selectedIndex == 2 ? 18 : 8,
                      spreadRadius: selectedIndex == 2 ? 2 : 0,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.directions_walk_rounded,
                    size: 26,
                    color: selectedIndex == 2 ? Colors.black : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int selectedIndex, int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 16 : 0,
                height: 2.5,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
