import 'package:flutter/material.dart';
import '../../models/walk_session.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/live_map_card.dart';
import '../../widgets/custom_button.dart';

class RouteDetailsScreen extends StatelessWidget {
  final WalkSession activity;

  const RouteDetailsScreen({super.key, required this.activity});

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    Text(
                      'Workout Detail',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('GPX file exported to Downloads.'), backgroundColor: AppColors.success),
                        );
                      },
                      icon: const Icon(Icons.download_rounded, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Large Map Path Card
                LiveMapCard(
                  points: activity.route,
                  height: 240,
                  interactive: true,
                ),
                const SizedBox(height: 24),

                // Title + Date Row
                Text(
                  'Walk Session',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.wb_sunny_outlined, size: 14, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Text(
                      '${activity.startTime.toString().substring(0, 16)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Detailed metrics Grid
                GlassCard(
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.5,
                    children: [
                      _buildMetricTile('Distance Covered', '${activity.distanceKm} km', AppColors.secondary),
                      _buildMetricTile('Duration', activity.durationString, AppColors.accent),
                      _buildMetricTile('Steps Count', '${activity.steps}', AppColors.primary),
                      _buildMetricTile('Calories Burned', '${activity.calories} kcal', AppColors.danger),
                      _buildMetricTile('Average Speed', '${activity.avgSpeedKmH} km/h', AppColors.secondary),
                      _buildMetricTile('Maximum Speed', '${activity.maxSpeedKmH} km/h', AppColors.danger),
                      _buildMetricTile('Average Pace', '${activity.paceString} /km', AppColors.accent),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Export Button
                CustomButton(
                  text: 'Export GPS Route (.gpx)',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('GPX file exported to Downloads.'), backgroundColor: AppColors.success),
                    );
                  },
                  type: ButtonType.primary,
                  icon: const Icon(Icons.share_location_rounded, color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
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
