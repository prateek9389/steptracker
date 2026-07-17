import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_button.dart';
import '../../providers/profile_provider.dart';

class WeightTrackerScreen extends ConsumerStatefulWidget {
  const WeightTrackerScreen({super.key});

  @override
  ConsumerState<WeightTrackerScreen> createState() => _WeightTrackerScreenState();
}

class _WeightTrackerScreenState extends ConsumerState<WeightTrackerScreen> {
  final TextEditingController _weightInputController = TextEditingController();

  @override
  void dispose() {
    _weightInputController.dispose();
    super.dispose();
  }

  void _showAddWeightDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Add Weight Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Input your current weight to recalculate BMI metrics.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: _weightInputController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: 'e.g. 74.5',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
            ),
            ElevatedButton(
              onPressed: () {
                final weightStr = _weightInputController.text;
                final weight = double.tryParse(weightStr);
                if (weight != null && weight > 0) {
                  // ref.read(profileProvider.notifier).addWeight(weight);
                  _weightInputController.clear();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Weight entry saved successfully!'), backgroundColor: AppColors.success),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid weight decimal value.'), backgroundColor: AppColors.danger),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Save Entry', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final p = profileState.value;

    if (p == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final spots = [FlSpot(0, p.weight)];

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
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.monitor_weight_rounded, color: AppColors.accent, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Weight & BMI Tracker',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
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
                  // Weight History Chart
                  GlassCard(
                    padding: const EdgeInsets.fromLTRB(12, 16, 24, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('WEIGHT TRENDS (kg)', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 150,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(
                                show: true,
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  gradient: AppColors.neonPurpleGradient,
                                  barWidth: 4,
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [AppColors.accent.withOpacity(0.2), AppColors.accent.withOpacity(0.0)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                  dotData: const FlDotData(show: true),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // BMI Status Board
                  GlassCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('BODY MASS INDEX', style: TextStyle(color: AppColors.textMutedDark, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  p.bmi.toStringAsFixed(1),
                                  style: theme.textTheme.displayMedium?.copyWith(fontFamily: 'Outfit', fontWeight: FontWeight.w900, fontSize: 32),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  p.bmiCategory.toUpperCase(),
                                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // BMI Color Ring representation
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.speed_rounded, color: AppColors.primary, size: 28),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Entry Log Timeline
                  Text('History Timeline', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 0,
                    itemBuilder: (context, idx) {
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 20),

                  // Add weight button
                  CustomButton(
                    text: 'Record New Weight Entry',
                    onPressed: _showAddWeightDialog,
                    type: ButtonType.accent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
