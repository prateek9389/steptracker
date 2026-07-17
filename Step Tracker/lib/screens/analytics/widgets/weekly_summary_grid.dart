import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stride_ai/providers/weekly_analytics_provider.dart';

class WeeklySummaryGrid extends StatelessWidget {
  final WeeklyAnalyticsState state;

  const WeeklySummaryGrid({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 3 * 12) / 4;
        
        // If screen is too narrow for 4 items, use 2x2 grid
        if (cardWidth < 70) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildCard(isDark, Icons.directions_walk_rounded, const Color(0xFF6324D6), 'Total Steps', NumberFormat('#,###').format(state.totalSteps), '', '91% of Goal', true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCard(isDark, Icons.location_on_rounded, const Color(0xFF10B981), 'Distance', state.totalDistance.toStringAsFixed(1), 'km', '${state.distanceIncrease > 0 ? '+' : ''}${state.distanceIncrease.toStringAsFixed(1)}% vs last week', false)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildCard(isDark, Icons.local_fire_department_rounded, const Color(0xFFF97316), 'Calories', NumberFormat('#,###').format(state.totalCalories), 'kcal', '${state.caloriesIncrease > 0 ? '+' : ''}${state.caloriesIncrease.toStringAsFixed(1)}% vs last week', false)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCard(isDark, Icons.timer_outlined, const Color(0xFF3B82F6), 'Active Time', _formatDuration(state.totalActiveMinutes), '', '${state.activeTimeIncrease > 0 ? '+' : ''}${state.activeTimeIncrease.toStringAsFixed(1)}% vs last week', false)),
                ],
              ),
            ],
          );
        }
        
        return Row(
          children: [
            Expanded(child: _buildCard(isDark, Icons.directions_walk_rounded, const Color(0xFF6324D6), 'Total Steps', NumberFormat('#,###').format(state.totalSteps), '', '91% of Goal', true)),
            const SizedBox(width: 12),
            Expanded(child: _buildCard(isDark, Icons.location_on_rounded, const Color(0xFF10B981), 'Distance', state.totalDistance.toStringAsFixed(1), 'km', '${state.distanceIncrease > 0 ? '+' : ''}${state.distanceIncrease.toStringAsFixed(1)}% vs last week', false)),
            const SizedBox(width: 12),
            Expanded(child: _buildCard(isDark, Icons.local_fire_department_rounded, const Color(0xFFF97316), 'Calories', NumberFormat('#,###').format(state.totalCalories), 'kcal', '${state.caloriesIncrease > 0 ? '+' : ''}${state.caloriesIncrease.toStringAsFixed(1)}% vs last week', false)),
            const SizedBox(width: 12),
            Expanded(child: _buildCard(isDark, Icons.timer_outlined, const Color(0xFF3B82F6), 'Active Time', _formatDuration(state.totalActiveMinutes), '', '${state.activeTimeIncrease > 0 ? '+' : ''}${state.activeTimeIncrease.toStringAsFixed(1)}% vs last week', false)),
          ],
        );
      }
    );
  }
  
  String _formatDuration(int minutes) {
    final int hours = minutes ~/ 60;
    final int mins = minutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  Widget _buildCard(bool isDark, IconData icon, Color color, String title, String value, String unit, String subtitle, bool isSteps) {
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey[200]!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(unit, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (isSteps)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF6324D6)))),
                const SizedBox(height: 4),
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.91,
                    child: Container(decoration: BoxDecoration(color: const Color(0xFF6324D6), borderRadius: BorderRadius.circular(2))),
                  ),
                ),
              ],
            )
          else
            FittedBox(fit: BoxFit.scaleDown, child: Text(subtitle, style: TextStyle(fontSize: 10, color: subtitle.contains('+') ? const Color(0xFF10B981) : (isDark ? Colors.white54 : Colors.black54)))),
        ],
      ),
    );
  }
}

// Needed to format numbers
String _formatNumber(int n) {
  return n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
}
