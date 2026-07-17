import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:stride_ai/providers/weekly_analytics_provider.dart';

class WeeklyTrendsCard extends StatelessWidget {
  final WeeklyAnalyticsState state;

  const WeeklyTrendsCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAveragesCard(context),
        const SizedBox(height: 16),
        _buildComparisonCard(context),
      ],
    );
  }

  Widget _buildAveragesCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey[200]!;

    final paceStr = state.avgDistance > 0 ? '${state.avgPace.toInt()}:${((state.avgPace - state.avgPace.toInt()) * 60).toInt().toString().padLeft(2, '0')}' : '0:00';
    
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
          Text('Weekly Trends', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 16),
          _buildDetailRow(isDark, Icons.directions_walk_rounded, const Color(0xFF6324D6), 'Avg. Steps', NumberFormat('#,###').format(state.avgSteps), ''),
          _buildDetailRow(isDark, Icons.location_on_rounded, const Color(0xFF10B981), 'Avg. Distance', state.avgDistance.toStringAsFixed(1), 'km'),
          _buildDetailRow(isDark, Icons.local_fire_department_rounded, const Color(0xFFF97316), 'Avg. Calories', NumberFormat('#,###').format(state.avgCalories), 'kcal'),
          _buildDetailRow(isDark, Icons.speed_rounded, const Color(0xFF6324D6), 'Avg. Pace', paceStr, 'min/km'),
          _buildDetailRow(isDark, Icons.speed_rounded, const Color(0xFF6324D6), 'Avg. Speed', state.avgSpeed.toStringAsFixed(1), 'km/h'),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey[200]!;
    final primaryPurple = const Color(0xFF6324D6);
    
    int maxSteps = 0;
    for (var stat in state.currentWeekStats) {
      if (stat.steps > maxSteps) maxSteps = stat.steps;
    }
    for (var stat in state.previousWeekStats) {
      if (stat.steps > maxSteps) maxSteps = stat.steps;
    }

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
          Text('This Week vs Last Week', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This Week', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
                  Text(NumberFormat('#,###').format(state.totalSteps), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryPurple)),
                ],
              ),
              Row(
                children: [
                  Icon(state.stepsIncrease >= 0 ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded, color: state.stepsIncrease >= 0 ? const Color(0xFF10B981) : Colors.red, size: 24),
                  Text('${state.stepsIncrease.abs().toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: state.stepsIncrease >= 0 ? const Color(0xFF10B981) : Colors.red)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Last Week', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
                  Text(NumberFormat('#,###').format(state.prevTotalSteps), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxSteps > 0 ? maxSteps * 1.2 : 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: _getSpots(state.previousWeekStats),
                    isCurved: true,
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: _getSpots(state.currentWeekStats),
                    isCurved: true,
                    color: primaryPurple,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: Colors.white,
                          strokeWidth: 1.5,
                          strokeColor: primaryPurple,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [primaryPurple.withOpacity(0.3), primaryPurple.withOpacity(0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getSpots(List<dynamic> stats) {
    List<FlSpot> spots = [];
    List<int> stepsArray = List.filled(7, 0);
    for (var stat in stats) {
      int index = stat.date.weekday - 1;
      if (index >= 0 && index < 7) {
        stepsArray[index] = stat.steps;
      }
    }
    for (int i = 0; i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), stepsArray[i].toDouble()));
    }
    return spots;
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
