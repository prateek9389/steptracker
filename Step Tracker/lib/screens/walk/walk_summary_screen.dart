import 'package:flutter/material.dart';
import '../../models/walk_session.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/live_map_card.dart';
import '../../widgets/custom_button.dart';

class WalkSummaryScreen extends StatelessWidget {
  final WalkSession activity;

  const WalkSummaryScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkBgGradient : const LinearGradient(
            colors: [Color(0xFFE2E8F0), Color(0xFFF8FAFC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Celebration Title
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.primary,
                      size: 54,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Workout Complete!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'StrideAI recorded your stats and boosted your Level XP.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 32),

                // Map Path Visualizer Card
                LiveMapCard(
                  points: activity.route,
                  height: 180,
                  interactive: true,
                ),
                const SizedBox(height: 24),

                // Stats Grid
                GlassCard(
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.5,
                    children: [
                      _buildSummaryStat('Distance', '${activity.distanceKm.toStringAsFixed(2)} km', AppColors.secondary),
                      _buildSummaryStat('Steps Taken', '${activity.steps}', AppColors.primary),
                      _buildSummaryStat('Duration', activity.durationString, AppColors.accent),
                      _buildSummaryStat('Calories', '${activity.calories} kcal', AppColors.danger),
                      _buildSummaryStat('Avg Pace', '${activity.paceString} /km', const Color(0xFF8B5CF6)),
                      _buildSummaryStat('Avg Speed', '${activity.avgSpeedKmH.toStringAsFixed(1)} km/h', const Color(0xFFF59E0B)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Action controls
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Share Progress',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sharing layout captured.'), backgroundColor: AppColors.success),
                          );
                        },
                        type: ButtonType.outline,
                        icon: const Icon(Icons.share_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        text: 'Save & Finish',
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
                        },
                        type: ButtonType.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMutedDark, fontSize: 10, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(width: 4, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
