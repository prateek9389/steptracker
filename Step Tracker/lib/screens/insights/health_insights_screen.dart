import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';

class HealthInsightsScreen extends StatelessWidget {
  const HealthInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        border: Border.all(
          color: isDark ? const Color(0x1AFFFFFF) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header drawer grabber
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

          // Title Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics_rounded, color: AppColors.secondary, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'AI Health Insights',
                      style: theme.textTheme.displaySmall?.copyWith(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 24),
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
          const Divider(color: Colors.white10, height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Weekly report card
                  GlassCard(
                    borderColor: AppColors.secondary.withOpacity(0.3),
                    gradient: LinearGradient(
                      colors: isDark ? [const Color(0xFF0B1D28), const Color(0xFF0B1220)] : [Colors.white, const Color(0xFFE0F7FF)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('WEEKLY HEALTH STATUS', style: TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: const Text('IMPROVING', style: TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your walking cadence increased by 8.4% compared to last week! Excellent work maintaining a consistent cardiovascular workload.',
                          style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Diagnostics list
                  Text('Summary Analytics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDiagnosticTile('Avg Daily Steps', '9,425 Steps', Icons.directions_walk_rounded, AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDiagnosticTile('Best Walk Time', '8:15 AM', Icons.schedule_rounded, AppColors.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDiagnosticTile('Calories Burned', '2,480 kcal', Icons.local_fire_department_rounded, AppColors.danger),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDiagnosticTile('Walking Trend', '+12% distance', Icons.trending_up_rounded, AppColors.success),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // AI suggestions list
                  Text('StrideAI Suggestions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildSuggestionItem(
                    icon: Icons.lightbulb_rounded,
                    title: 'Post-Meal Walking Benefit',
                    desc: 'A brief 10-minute walk after lunch can help lower blood glucose levels by up to 22% compared to static rest.',
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: 16),
                  _buildSuggestionItem(
                    icon: Icons.directions_run_rounded,
                    title: 'Cadence Suggestion',
                    desc: 'To improve aerobic base, try to maintain a step frequency of 100-110 steps/min. Use our Running mode for interval reminders.',
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticTile(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textMutedDark, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                const SizedBox(height: 6),
                Text(desc, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
