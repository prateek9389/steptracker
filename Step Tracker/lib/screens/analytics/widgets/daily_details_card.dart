import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stride_ai/providers/weekly_analytics_provider.dart';
import 'package:stride_ai/providers/profile_provider.dart';
import 'package:stride_ai/models/daily_stat.dart';

class DailyDetailsCard extends ConsumerWidget {
  final WeeklyAnalyticsState state;
  final int selectedIndex;

  const DailyDetailsCard({
    super.key,
    required this.state,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileStreamProvider).value;
    final int goal = profile?.dailyGoal ?? 6000;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey[200]!;
    final primaryPurple = const Color(0xFF6324D6);
    
    // Find stat for selected index
    DailyStat? stat;
    for (var s in state.currentWeekStats) {
      if (s.date.weekday - 1 == selectedIndex) {
        stat = s;
        break;
      }
    }
    
    // Fallback date if stat is missing
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final date = stat?.date ?? startOfWeek.add(Duration(days: selectedIndex));
    
    final steps = stat?.steps ?? 0;
    final distance = stat?.distanceKm ?? 0.0;
    final calories = stat?.calories ?? 0;
    final activeMins = stat?.activeMinutes ?? 0;
    
    final paceStr = distance > 0 ? '${activeMins ~/ distance}:${((activeMins / distance - (activeMins ~/ distance)) * 60).toInt().toString().padLeft(2, '0')}' : '0:00';
    final speedStr = activeMins > 0 ? (distance / (activeMins / 60.0)).toStringAsFixed(1) : '0.0';
    final goalCompleted = steps >= goal;
    
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
          Text('Daily Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(DateFormat('E').format(date).toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(DateFormat('d').format(date), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('EEEE').format(date), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    Text(DateFormat('d MMM yyyy').format(date), style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: isDark ? Colors.white54 : Colors.black54),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white54 : Colors.black54),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(isDark, Icons.directions_walk_rounded, const Color(0xFF6324D6), 'Steps', NumberFormat('#,###').format(steps), ''),
          _buildDetailRow(isDark, Icons.location_on_rounded, const Color(0xFF10B981), 'Distance', distance.toStringAsFixed(1), 'km'),
          _buildDetailRow(isDark, Icons.local_fire_department_rounded, const Color(0xFFF97316), 'Calories', NumberFormat('#,###').format(calories), 'kcal'),
          _buildDetailRow(isDark, Icons.timer_outlined, const Color(0xFF3B82F6), 'Active Time', _formatDuration(activeMins), ''),
          _buildDetailRow(isDark, Icons.speed_rounded, const Color(0xFF6324D6), 'Avg. Pace', paceStr, 'min/km'),
          _buildDetailRow(isDark, Icons.speed_rounded, const Color(0xFF6324D6), 'Avg. Speed', speedStr, 'km/h'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: const Color(0xFF10B981), size: 16),
                  const SizedBox(width: 8),
                  Text('Goal', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
                ],
              ),
              Row(
                children: [
                  Icon(goalCompleted ? Icons.check_circle_rounded : Icons.pending_actions_rounded, color: goalCompleted ? const Color(0xFF10B981) : Colors.orange, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    goalCompleted ? 'Completed' : 'Pending',
                    style: TextStyle(color: goalCompleted ? const Color(0xFF10B981) : Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    final int hours = minutes ~/ 60;
    final int mins = minutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  Widget _buildDetailRow(bool isDark, IconData icon, Color color, String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(unit, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
              ]
            ],
          ),
        ],
      ),
    );
  }
}
