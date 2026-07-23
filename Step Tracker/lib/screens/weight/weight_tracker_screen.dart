import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_button.dart';
import '../../providers/profile_provider.dart';
import '../../models/weight_entry.dart';

class WeightTrackerScreen extends ConsumerStatefulWidget {
  const WeightTrackerScreen({super.key});

  @override
  ConsumerState<WeightTrackerScreen> createState() => _WeightTrackerScreenState();
}

class _WeightTrackerScreenState extends ConsumerState<WeightTrackerScreen> {
  final TextEditingController _weightInputController = TextEditingController();
  List<WeightEntry> _weightHistory = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _weightInputController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingHistory = false);
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('weight_history')
          .orderBy('date', descending: false)
          .get();
      final entries = snap.docs
          .map((doc) => WeightEntry.fromJson(doc.data(), doc.id))
          .toList();
      setState(() {
        _weightHistory = entries;
        _loadingHistory = false;
      });
    } catch (_) {
      setState(() => _loadingHistory = false);
    }
  }

  void _showAddWeightDialog() {
    final p = ref.read(profileStreamProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Add Weight Entry', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Input your current weight to recalculate BMI metrics.', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: _weightInputController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
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
              child: Text('Cancel', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            ),
            ElevatedButton(
              onPressed: () async {
                final weightStr = _weightInputController.text;
                final weight = double.tryParse(weightStr);
                if (weight != null && weight > 0 && p != null) {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid == null) return;

                  // Compute BMI using current height and new weight
                  final heightM = p.height / 100.0;
                  final bmi = weight / (heightM * heightM);

                  final entry = WeightEntry(
                    weightKg: weight,
                    bmi: bmi,
                    date: DateTime.now(),
                  );

                  try {
                    // Save to Firestore weight_history sub-collection
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('weight_history')
                        .add(entry.toJson());

                    // Update the user's profile weight field
                    await ref.read(profileRepositoryProvider).saveProfile(
                          p.copyWith(weight: weight),
                        );

                    _weightInputController.clear();
                    if (context.mounted) Navigator.of(context).pop();

                    // Reload history to reflect new entry
                    await _loadHistory();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Weight entry saved!'), backgroundColor: AppColors.success),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppColors.danger),
                      );
                    }
                  }
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

    // Build chart spots from history, or fall back to single profile weight point
    List<FlSpot> spots;
    if (_weightHistory.isEmpty) {
      spots = [FlSpot(0, p.weight)];
    } else {
      spots = _weightHistory.asMap().entries.map((e) {
        return FlSpot(e.key.toDouble(), e.value.weightKg);
      }).toList();
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2;

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
            child: _loadingHistory
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : SingleChildScrollView(
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
                                    minY: minY,
                                    maxY: maxY,
                                    gridData: const FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 36,
                                          getTitlesWidget: (value, meta) => Text(
                                            value.toStringAsFixed(0),
                                            style: const TextStyle(fontSize: 9, color: AppColors.textMutedDark),
                                          ),
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: _weightHistory.length > 1,
                                          getTitlesWidget: (value, meta) {
                                            final idx = value.toInt();
                                            if (idx < 0 || idx >= _weightHistory.length) return const SizedBox.shrink();
                                            final date = _weightHistory[idx].date;
                                            return Text('${date.day}/${date.month}', style: const TextStyle(fontSize: 8, color: AppColors.textMutedDark));
                                          },
                                        ),
                                      ),
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
                        if (_weightHistory.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(
                              'No weight entries yet. Tap the button below to log your first entry!',
                              style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _weightHistory.reversed.toList().length,
                            itemBuilder: (context, idx) {
                              final entry = _weightHistory.reversed.toList()[idx];
                              final dateStr =
                                  '${entry.date.day}/${entry.date.month}/${entry.date.year}';
                              final timeStr =
                                  '${entry.date.hour.toString().padLeft(2, '0')}:${entry.date.minute.toString().padLeft(2, '0')}';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF161E2E) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: isDark ? Colors.white12 : Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.monitor_weight_rounded,
                                          color: AppColors.accent, size: 18),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$dateStr at $timeStr',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? AppColors.textSecondaryDark
                                                  : AppColors.textSecondaryLight,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'BMI: ${entry.bmi.toStringAsFixed(1)}',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${entry.weightKg.toStringAsFixed(1)} kg',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              );
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
